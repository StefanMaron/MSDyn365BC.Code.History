page 317 "VAT Statement"
{
    ApplicationArea = VAT;
    AutoSplitKey = true;
    Caption = 'VAT Statements';
    MultipleNewLines = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "VAT Statement Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentStmtName; CurrentStmtName)
            {
                ApplicationArea = VAT;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the VAT statement.';

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
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field("Box No."; "Box No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number on the packaging box that the VAT statement applies to.';
                }
                field(Type; Type)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Account Totaling"; "Account Totaling")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies an account interval or a series of account numbers.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccountList: Page "G/L Account List";
                    begin
                        GLAccountList.LookupMode(true);
                        if not (GLAccountList.RunModal = ACTION::LookupOK) then
                            exit(false);
                        Text := GLAccountList.GetSelectionFilter;
                        exit(true);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("G/L Amount Type"; "G/L Amount Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the general ledger amount type for the VAT statement line.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the code for the Gen. Prod. Posting Group that applies to the entry.';
                }
                field("EU-3 Party Trade"; "EU-3 Party Trade")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether the document is part of a three-party trade.';
                }
                field("EU 3-Party Intermediate Role"; "EU 3-Party Intermediate Role")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies when the sales haeder will use European Union third-party intermediate trade rules. This option complies with VAT accounting standards for EU third-party trade.';
                }
                field("Prepayment Type"; "Prepayment Type")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the VAT statement prepayment type.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts or the base amounts on which the VAT is calculated.';
                }
                field("Use Row Date Filter"; "Use Row Date Filter")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you need to use a filter date other than the date on the VAT statement.';
                }
                field("Row Totaling"; "Row Totaling")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a row-number interval or a series of row numbers.';
                }
                field("Calculate with"; "Calculate with")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether amounts on the VAT statement will be calculated with their original sign or with the sign reversed.';
                }
                field(Control22; Print)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether the VAT statement line will be printed on the report that contains the finished VAT statement.';
                }
                field(Show; Show)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if acc. schedule line will be show';
                }
                field("Print with"; "Print with")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether amounts on the VAT statement will be printed with their original sign or with the sign reversed.';
                }
                field("New Page"; "New Page")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether a new page should begin immediately after this line when the VAT statement is printed. To start a new page after this line, place a check mark in the field.';
                }
                field("Attribute Code"; "Attribute Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies xml code for export.';
                }
                field("VAT Control Rep. Section Code"; "VAT Control Rep. Section Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the section code for the VAT control report.';
                }
                field("Ignore Simpl. Tax Doc. Limit"; "Ignore Simpl. Tax Doc. Limit")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether the system will or will not check the Simpl. Tax document limit for VAT statement depending on whether the field is checked.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("VAT &Statement")
            {
                Caption = 'VAT &Statement';
                Image = Suggest;
                action("P&review")
                {
                    ApplicationArea = VAT;
                    Caption = 'P&review';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "VAT Statement Preview";
                    RunPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                                  Name = FIELD("Statement Name");
                    ToolTip = 'Preview the VAT statement report.';
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
                    ApplicationArea = VAT;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintVATStmtLine(Rec);
                    end;
                }
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = VAT;
                    Caption = 'Calculate and Post VAT Settlement';
                    Ellipsis = true;
                    Image = SettleOpenTransactions;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Report "Calc. and Post VAT Settlement";
                    ToolTip = 'Close open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account.';
                }
                action(Export)
                {
                    ApplicationArea = VAT;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Export VAT Statement";
                    RunPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                                  Name = FIELD("Statement Name");
                    ToolTip = 'Allows the VAT statement report export to xml.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        StmtSelected: Boolean;
    begin
        OpenedFromBatch := ("Statement Name" <> '') and ("Statement Template Name" = '');
        if OpenedFromBatch then begin
            CurrentStmtName := "Statement Name";
            VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
            exit;
        end;
        VATStmtManagement.TemplateSelection(PAGE::"VAT Statement", Rec, StmtSelected);
        if not StmtSelected then
            Error('');
        VATStmtManagement.OpenStmt(CurrentStmtName, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        VATStmtManagement: Codeunit VATStmtManagement;
        CurrentStmtName: Code[10];
        OpenedFromBatch: Boolean;

    local procedure CurrentStmtNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        VATStmtManagement.SetName(CurrentStmtName, Rec);
        CurrPage.Update(false);
    end;
}

