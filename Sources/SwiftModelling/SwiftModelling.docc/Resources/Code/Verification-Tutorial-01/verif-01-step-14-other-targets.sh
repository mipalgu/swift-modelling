# The same metamodel and model for TLA+, Event-B and Lean 4, one directory each
swift-ecore generate Organisation.ecore --language tla --model office.xmi --output verification-tla
swift-ecore generate Organisation.ecore --language eventb --model office.xmi --output verification-eventb
swift-ecore generate Organisation.ecore --language lean --model office.xmi --output verification-lean
ls verification-tla verification-eventb verification-lean

# Output:
# Generated 3 files in: .../verification-tla
# Generated 4 files in: .../verification-eventb
# Generated 2 files in: .../verification-lean
# verification-eventb:
# office_instance_ctx.bucx
# office_instance_machine.bumx
# organisation_ctx.bucx
# organisation_machine.bumx
# verification-lean:
# OfficeInstance.lean
# Organisation.lean
# verification-tla:
# office_instance.cfg
# office_instance.tla
# organisation.tla
