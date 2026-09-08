<!-- GEURTS-AUDIENCE: AI-READ -->
# Moved: Geurts Game Forge Intelligence Integration Contract

**Version:** 2.0.0
**Status:** Non-normative compatibility redirect
**Legacy compatibility redirect path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`

The normative integration boundary and only manifest-selected path moved to `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md`. `GeurtsTechniqueManifest.md` selects only the new technique; never load both as authorities.

This file exists only for a released consumer that hardcodes the old path. The former v1 stateful launch-check/download, transaction, rollback, recovery, drift-preservation, and reintegration lifecycle is obsolete and must not be implemented from an older copy. Resolve the v2 notification-and-manual-update contract from the manifest-selected technique.

A consumer that cannot resolve the new manifest-selected technique must fail closed and must not treat this redirect as an integration authority.
