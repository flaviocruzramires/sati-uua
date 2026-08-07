# Bug — Listagem de Chamados Não Atualiza Após Encerrar

**Versão:** 1.0  
**Data:** 2026-07-31  
**Severidade:** Média (UX ruim, mas sem perda de dados)

---

## Descrição

Ao encerrar um chamado via "Marcar como encerrado" na tela de detalhe, a situação
do chamado é atualizada no servidor (status 201), mas ao voltar para a listagem
o card ainda aparece com a situação anterior. Precisa de Ctrl+F5 para atualizar.

---

## Causa raiz

O `chamadosListViewModelProvider` é um `Notifier` que carrega os dados na inicialização
via `Future.microtask(load)`. Quando o usuário navega para o detalhe e volta, o provider
**não é recriado** (Riverpod mantém o estado em cache) e a lista não é recarregada.

Fluxo atual:
```
/chamados → lista carregada → navega para /chamados/123 → encerra → volta para /chamados
                                                                       ↑
                                                        lista ainda tem estado antigo
```

---

## Soluções possíveis

### Opção A — Invalidar o provider ao voltar (recomendada)

No `chamado_detalhe_view.dart`, ao salvar com sucesso (`marcaEncerramento = true`),
invalidar o provider da listagem:

```dart
// Após salvar com sucesso:
if (ok && mounted) {
  ref.invalidate(chamadosListViewModelProvider); // força reload na volta
  _descricaoCtrl.clear();
  ...
}
```

Também invalidar em `assumirChamado` e em qualquer outra ação que mude situação.

**Prós:** simples, cirúrgico, sem polling.  
**Contras:** só funciona se o usuário estiver na mesma sessão (sem abas separadas).

### Opção B — Recarregar ao entrar na rota `/chamados`

Usar `GoRouter`'s `onEnter` ou um hook de ciclo de vida para forçar `vm.load()`
quando a rota de listagem é (re)ativada:

```dart
// No build da ChamadosListView, usar ref.listen ou um LifecycleObserver
// para detectar quando a rota fica visível novamente
```

**Prós:** garante dados frescos sempre que o usuário vê a lista.  
**Contras:** mais chamadas de rede; mais complexo de implementar com GoRouter.

### Opção C — Atualizar o item localmente sem chamar a API

Quando o detalhe fecha com `marcaEncerramento = true`, atualizar o item
diretamente no estado do `chamadosListViewModelProvider` sem recarregar tudo.

**Prós:** zero chamada extra de rede, transição instantânea.  
**Contras:** o estado local pode divergir se outro usuário mudou o chamado.

---

## Decisão recomendada

**Opção A** como solução imediata — invalidar o provider em todas as ações que
mudam a situação do chamado (encerrar, assumir). Simples de implementar e resolve
o bug reportado.

Futuramente, quando notificações em tempo real (doc 04 — WebSocket) forem
implementadas, a listagem pode ser atualizada de forma reativa.

---

## Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `chamado_detalhe_view_model.dart` | Expor método/evento de invalidação ou receber `Ref` para invalidar |
| `chamado_detalhe_view.dart` | Após `registrarAtendimento` com encerramento, chamar `ref.invalidate(chamadosListViewModelProvider)` |
| `chamado_detalhe_view.dart` | Idem para `assumirChamado` |

---

## Implementação (Opção A — detalhada)

```dart
// chamado_detalhe_view.dart — no _RegistroFormState._submit():
final ok = await widget.vm.registrarAtendimento(...);
if (ok && mounted) {
  if (_marcarEncerrado) {
    // Invalida a listagem para que ela recarregue ao voltar
    ref.invalidate(chamadosListViewModelProvider);
  }
  _descricaoCtrl.clear();
  setState(() { ... });
}
```

Para ter acesso ao `ref` dentro do `StatefulWidget`, converter `_RegistroForm`
para `ConsumerStatefulWidget`, ou passar a função de invalidação como callback:

```dart
// Alternativa: passar callback do widget pai (que já é ConsumerWidget)
class _RegistroForm extends StatefulWidget {
  final VoidCallback? onChamadoEncerrado;  // novo parâmetro
  ...
}
// No _DetalheBody (que é StatelessWidget filho de ConsumerWidget):
_RegistroForm(
  ...
  onChamadoEncerrado: () => ref.invalidate(chamadosListViewModelProvider),
)
```

Esta segunda alternativa não requer converter `_RegistroForm` para `ConsumerStatefulWidget`.
