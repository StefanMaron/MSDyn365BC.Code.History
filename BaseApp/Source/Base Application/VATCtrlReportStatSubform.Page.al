page 31105 "VAT Ctrl.Report Stat. Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "VAT Control Report Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Control Rep. Section Code"; "VAT Control Rep. Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the section code for the VAT control report.';
                }
                field("VAT Control Rep. Section Desc."; "VAT Control Rep. Section Desc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the section code for the VAT control report.';
                }
                field("Base 1"; "Base 1")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total base amount for the base VAT.';
                }
                field("Base 2"; "Base 2")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total base amount for the reduced VAT.';
                }
                field("<Base 3>"; "Base 3")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total base amount for the reduced 2 VAT.';
                }
                field("Amount 1"; "Amount 1")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount for the base VAT.';
                }
                field("Amount 2"; "Amount 2")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount for the reduced VAT.';
                }
                field("Amount 3"; "Amount 3")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount for the reduced 2 VAT.';
                }
                field("Total Base"; "Total Base")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the Total Amount of all VAT Base for selected VAT Ctrl. Report statement Section';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the Total Amount of all VAT for selected VAT Ctrl. Report statement Section';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure SetTempVATCtrlRepBuffer(var NewVATCtrlRptBuf: Record "VAT Control Report Buffer")
    begin
        DeleteAll();
        if NewVATCtrlRptBuf.FindSet then
            repeat
                Copy(NewVATCtrlRptBuf);
                Insert;
            until NewVATCtrlRptBuf.Next = 0;
        CurrPage.Update(false);
    end;
}

