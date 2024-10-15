page 12126 "Annual VAT Communication"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Annual VAT Communication';
    MultipleNewLines = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "VAT Statement Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            field(CurrentStmtName; CurrentStmtName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(VATStmtManagement.LookupName(GetRangeMax("Statement Template Name"), CurrentStmtName, Text));
                end;

                trigger OnValidate()
                begin
                    VATStmtManagement.CheckName(CurrentStmtName, Rec);
                    CurrentStmtNameOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("Account Totaling"; "Account Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totalling account.';
                    Visible = false;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group for the line.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group for the line.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the amount that is being reported. If the field is blank, then no information is reported.';
                }
                field("Row Totaling"; "Row Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for the line.';
                }
                field("Calculate with"; "Calculate with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount is calculated with a sign or the opposite sign.';
                }
                field("Round Factor"; "Round Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a rounding factor that is used to round the VAT entry amounts.';
                }
                field(Control22; Print)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to print the report.';
                }
                field("Annual VAT Comm. Field"; "Annual VAT Comm. Field")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sales or purchase transaction that created the VAT entry.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Annual VAT Communication")
            {
                Caption = '&Annual VAT Communication';
                action("P&review")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&review';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    RunObject = Page "Annual VAT Comm. Preview";
                    RunPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                                  Name = FIELD("Statement Name");
                    ToolTip = 'Preview the document.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Print the document.';

                    trigger OnAction()
                    var
                        VATStatementName: Record "VAT Statement Name";
                    begin
                        VATStatementName.SetFilter("Statement Template Name", '%1', "Statement Template Name");
                        if VATStatementName.FindLast() then
                            ReportPrint.PrintVATStmtName(VATStatementName);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Annual VAT Communication")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Annual VAT Communication';
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'View detailed information about VAT related transactions carried out during the year. ';

                trigger OnAction()
                var
                    VATStatementName: Record "VAT Statement Name";
                begin
                    VATStatementName.SetFilter("Statement Template Name", '%1', "Statement Template Name");
                    if VATStatementName.FindLast() then
                        ReportPrint.PrintVATStmtName(VATStatementName);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        StmtSelected: Boolean;
    begin
        VATStmtManagement.TemplateSelection(PAGE::"Annual VAT Communication", Rec, StmtSelected);
        if not StmtSelected then
            Error('');
        VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        VATStmtManagement: Codeunit VATStmtManagement;
        CurrentStmtName: Code[10];

    local procedure CurrentStmtNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        VATStmtManagement.SetName(CurrentStmtName, Rec);
        CurrPage.Update(false);
    end;
}

