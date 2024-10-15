page 17237 "Tax Reg. Payroll Line Subform"
{
    AutoSplitKey = true;
    Caption = 'Register Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Line Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Code"; "Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register line setup information.';
                }
                field("Check Exist Entry"; "Check Exist Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check exist entry associated with the tax register line setup information.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount type associated with the tax register line setup information.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with the tax register line setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLAcc.Reset;
                        if "Account No." <> '' then begin
                            GLAcc.SetFilter("No.", "Account No.");
                            if GLAcc.FindFirst then;
                            GLAcc.SetRange("No.");
                        end;
                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLAcc.Reset;
                        if "Bal. Account No." <> '' then begin
                            GLAcc.SetFilter("No.", "Bal. Account No.");
                            if GLAcc.FindFirst then;
                            GLAcc.SetRange("No.");
                        end;
                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Payroll Source"; "Payroll Source")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll source associated with the tax register line setup information.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourcePayTotaling;
                    end;
                }
                field("Element Type Filter"; "Element Type Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if general ledger corresponding dimension filter will be used with the tax register line setup information.';

                    trigger OnDrillDown()
                    begin
                        DrillDownElementTypeTotaling;
                    end;
                }
                field("Element Type Totaling"; "Element Type Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type total associated with the tax register line setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupElementTypeTotaling(Text));
                    end;
                }
                field("Payroll Source Totaling"; "Payroll Source Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll source total associated with the tax register line setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourcePayTotaling(Text));
                    end;
                }
                field("Employee Statistics Group Code"; "Employee Statistics Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee statistics group code associated with the tax register line setup information.';
                }
                field("Employee Category Code"; "Employee Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category code associated with the tax register line setup information.';
                }
                field("Payroll Posting Group"; "Payroll Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll posting group associated with the tax register line setup information.';
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        ShowDimensionsFilters;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Dimensions Filters");
        if "Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';
        PayrollSourceOnFormat(Format("Payroll Source"));
        ElementTypeFilterOnFormat(Format("Element Type Filter"));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DimFilters := '';
    end;

    var
        GLAcc: Record "G/L Account";
        Text1001: Label 'Present';
        DimFilters: Text[30];

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        CurrPage.SaveRecord;
        Commit;
        if "Line No." <> 0 then begin
            TaxRegDimFilter.FilterGroup(2);
            TaxRegDimFilter.SetRange("Section Code", "Section Code");
            TaxRegDimFilter.SetRange("Tax Register No.", "Tax Register No.");
            TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::"Entry Setup");
            TaxRegDimFilter.FilterGroup(0);
            TaxRegDimFilter.SetRange("Line No.", "Line No.");
            PAGE.RunModal(0, TaxRegDimFilter);
        end;
        CurrPage.Update(false);
    end;

    local procedure PayrollSourceOnFormat(Text: Text[1024])
    begin
        Text := FormatSourcePayTotaling;
    end;

    local procedure ElementTypeFilterOnFormat(Text: Text[1024])
    begin
        Text := FormatElementTypeTotaling;
    end;
}

