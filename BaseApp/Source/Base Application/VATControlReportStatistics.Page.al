#if not CLEAN17
page 31104 "VAT Control Report Statistics"
{
    Caption = 'VAT Control Report Statistics (Obsolete)';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "VAT Control Report Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.4';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of VAT control report.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of VAT control report.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies first date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies end date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of vies declarations';
                }
            }
            part(SubForm; "VAT Ctrl.Report Stat. Subform")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FilterGroup(2);
        SetRange("No.", "No.");
        FilterGroup(0);

        VATCtrlRptMgt.CreateBufferForStatistics(Rec, TempVATCtrlRptBuf, true);
        SetVATCtrlRepBuffer;
    end;

    var
        TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary;
        VATCtrlRptMgt: Codeunit VATControlReportManagement;

    local procedure SetVATCtrlRepBuffer()
    begin
        CurrPage.SubForm.PAGE.SetTempVATCtrlRepBuffer(TempVATCtrlRptBuf);
    end;
}
#endif