pageextension 31405 "Service Order CZ" extends "Service Order"
{
    layout
    {
#if not CLEAN22
#pragma warning disable AL0432
        modify("Intrastat Exclude CZL")
#pragma warning restore AL0432
        {
            Enabled = not IntrastatEnabled;
            Visible = not IntrastatEnabled;
        }
#endif
        addafter(IntrastatTransactionCZL)
        {
            field("Intrastat Exclude CZ"; Rec."Intrastat Exclude CZ")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Intrastat Exclude';
                ToolTip = 'Specifies that entry will be excluded from intrastat.';
#if not CLEAN22
                Enabled = IntrastatEnabled;
                Visible = IntrastatEnabled;
#endif
            }
        }
    }
#if not CLEAN22

    trigger OnOpenPage()
    begin
        IntrastatEnabled := IntrastatReportManagement.IsFeatureEnabled();
    end;

    var
        IntrastatReportManagement: Codeunit IntrastatReportManagement;
        IntrastatEnabled: Boolean;
#endif
}