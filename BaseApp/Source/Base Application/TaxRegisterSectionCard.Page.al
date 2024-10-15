page 17219 "Tax Register Section Card"
{
    Caption = 'Tax Register Section Card';
    PageType = Card;
    SourceTable = "Tax Register Section";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the tax register section.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register section.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status associated with the tax register section.';
                }
                field("Last GL Entries Date"; "Last GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last general ledger entry date for the tax register section.';
                }
                field("Last CV Entries Date"; "Last CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last creditor or debtor entry date for the tax register section.';
                }
                field("Last Item Entries Date"; "Last Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last item entry date for the tax register section.';
                }
                field("Last FA Entries Date"; "Last FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last fixed asset entry date for the tax register section.';
                }
                field("Last FE Entries Date"; "Last FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last future expenses entry date for the tax register section.';
                }
                field("Last PR Entries Date"; "Last PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last payroll entry date for the tax register section.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date associated with the tax register section.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date associated with the tax register section.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("Absence GL Entries Date"; "Absence GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when general ledger entries were not available for the tax register section.';
                }
                field("Absence CV Entries Date"; "Absence CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when credit or debtor entries were not available for the tax register section.';
                }
                field("Absence Item Entries Date"; "Absence Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when item entries were not available for the tax register section.';
                }
                field("Absence FA Entries Date"; "Absence FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when fixed asset entries were not available for the tax register section.';
                }
                field("Absence FE Entries Date"; "Absence FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when future expense entries were not available for the tax register section.';
                }
                field("Absence PR Entries Date"; "Absence PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when payroll entries were not available for the tax register section.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; "Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; "Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; "Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 4 Code"; "Dimension 4 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
            }
            group(Balance)
            {
                Caption = 'Balance';
                field("Debit Balance Point 1"; "Debit Balance Point 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Debit Balance Point 2"; "Debit Balance Point 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Debit Balance Point 3"; "Debit Balance Point 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Credit Balance Point 1"; "Credit Balance Point 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
            }
            group(System)
            {
                Caption = 'System';
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type associated with the tax register section.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the form identifier associated with the tax register section.';
                }
                field("Page Name"; "Page Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the form name associated with the tax register section.';
                }
                field("Norm Jurisdiction Code"; "Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the norm jurisdiction that is used to calculate taxable profits and losses for the tax difference.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Registers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Registers';
                Image = Register;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Tax Register Worksheet";
                RunPageLink = "Section Code" = FIELD(Code);
                ShortCutKey = 'Shift+Ctrl+L';
                ToolTip = 'View all related tax entries. Every register shows the first and last entry number of its entries.';
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Copy Section")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Section';
                    Image = CopyBudget;

                    trigger OnAction()
                    var
                        CopyTaxRegSection: Report "Copy Tax Register Section";
                    begin
                        Clear(CopyTaxRegSection);
                        TaxRegSection.SetRange(Code, Code);
                        CopyTaxRegSection.SetTableView(TaxRegSection);
                        CopyTaxRegSection.RunModal();
                        Clear(CopyTaxRegSection);
                    end;
                }
                separator(Action19)
                {
                }
                action("Create Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Registers';
                    Ellipsis = true;
                    Image = CalculateLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        TaxRegSection.SetRange(Code, Code);
                        REPORT.Run(REPORT::"Create Tax Registers", true, true, TaxRegSection);
                    end;
                }
                action("Clear Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Registers';
                    Image = ClearLog;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        ValidateChangeDeclaration;
                    end;
                }
                separator(Action1210000)
                {
                }
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        TaxRegSection.SetRange(Code, Code);
                        ExportSettings(TaxRegSection);
                    end;
                }
                action("Import Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Settings';
                    Ellipsis = true;
                    Image = Import;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Import setup information.';

                    trigger OnAction()
                    begin
                        ValidateChangeDeclaration;
                        PromptImportSettings;
                    end;
                }
            }
        }
    }

    var
        TaxRegSection: Record "Tax Register Section";
}

