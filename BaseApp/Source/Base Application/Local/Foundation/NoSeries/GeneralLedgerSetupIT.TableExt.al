#if not CLEANSCHEMA27
tableextension 12147 GeneralLedgerSetupIT extends "General Ledger Setup"
{
    fields
    {
        field(12147; "Use Legacy No. Series Lines"; Boolean)
        {
            Caption = 'Use Legacy No. Series Lines';
            ToolTip = 'Specifies whether to use the legacy No. Series Lines Sales and No. Series Line Purchase tables. Disabling this setting may affect installed extensions.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series Lines Sales and No. Series Line Purchase tables are obslete and will be removed in a future release.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
            InitValue = true;
        }
    }
}
#endif