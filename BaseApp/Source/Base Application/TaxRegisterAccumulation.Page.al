page 17209 "Tax Register Accumulation"
{
    Caption = 'Tax Register Accumulation';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Tax Register";

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = ',,Month,Quarter,Year';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    Editable = false;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                }
            }
            part(TaxRegAccLines; "Tax Register Accum. Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Section Code" = FIELD("Section Code"),
                              "Tax Register No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter");
                SubPageView = SORTING("Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            action(Entries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entries';
                Image = Entries;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Ctrl+F7';
                ToolTip = 'View the entries for the tax register.';

                trigger OnAction()
                begin
                    ShowTaxRegEntries;
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Image = Print;
                Promoted = true;
                PromotedCategory = "Report";

                trigger OnAction()
                begin
                    PrintReport(DateFilter);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PeriodType := PeriodType::Month;
        FindPeriod('');
    end;

    var
        PeriodType: Option ,,Month,Quarter,Year;
        DateFilter: Text[250];

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Month);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
        DateFilter := StrSubstNo('%1..%2', Calendar."Period Start", Calendar."Period End");
        SetFilter("Date Filter", '%1..%2', CalcDate('<-CM>', Calendar."Period End"), Calendar."Period End");
        CurrPage.TaxRegAccLines.PAGE.UpdatePage(DateFilter);
    end;

    local procedure ShowTaxRegEntries()
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        if ("Page ID" = 0) or ("Table ID" = 0) or
           ("Storing Method" = "Storing Method"::Calculation)
        then
            exit;

        case "Table ID" of
            DATABASE::"Tax Register G/L Entry":
                begin
                    TaxRegGLEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    PAGE.RunModal("Page ID", TaxRegGLEntry);
                end;
            DATABASE::"Tax Register CV Entry":
                begin
                    TaxRegCVEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    PAGE.RunModal("Page ID", TaxRegCVEntry);
                end;
            DATABASE::"Tax Register Item Entry":
                begin
                    TaxRegItemEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    PAGE.RunModal("Page ID", TaxRegItemEntry);
                end;
            DATABASE::"Tax Register FA Entry":
                begin
                    TaxRegFAEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    PAGE.RunModal("Page ID", TaxRegFAEntry);
                end;
            DATABASE::"Tax Register FE Entry":
                begin
                    TaxRegFEEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    PAGE.RunModal("Page ID", TaxRegFEEntry);
                end;
        end;
    end;
}

