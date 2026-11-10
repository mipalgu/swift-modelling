# Validate the draft rules
# Expected error: payBonus never binds its VAR parameter bonus
swift-henshin validate draft.henshin_text

# Output:
# warning: draft.henshin_text: Rule 'renameClient' declares parameter 'note' but uses it nowhere [henshin.unused-parameter]
# warning: draft.henshin_text: Rule 'removeAccount' deletes a node of class 'Account' without its containment edge [henshin.deletion-without-containment]
# error: draft.henshin_text: Rule 'payBonus' never matches its VAR parameter 'bonus' in its left-hand side [henshin.var-parameter-not-in-lhs]
# draft.henshin_text: 1 error(s), 2 warning(s)
