page 474 "VAT Statement Preview"
{
    Caption = 'VAT Statement Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "VAT Statement Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VATPeriodStartDate; VATPeriodStartDate)
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Period Start Date';
                    LookupPageID = "VAT Periods";
                    TableRelation = "VAT Period";
                    ToolTip = 'Specifies the starting date for the VAT period.';

                    trigger OnValidate()
                    begin
                        if VATPeriodStartDate <> 0D then begin
                            VATPeriod.Get(VATPeriodStartDate);
                            if VATPeriod.Next > 0 then
                                VATPeriodEndDate := CalcDate('<-1D>', VATPeriod."Starting Date");
                        end;
                        SetRange("Date Filter", VATPeriodStartDate, VATPeriodEndDate);
                        DateFilter := GetFilter("Date Filter"); // NAVCZ
                        UpdateSubForm;
                    end;
                }
                field(VATPeriodEndDate; VATPeriodEndDate)
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Period End Date';
                    ToolTip = 'Specifies the ending date for the VAT period.';

                    trigger OnValidate()
                    begin
                        SetRange("Date Filter", VATPeriodStartDate, VATPeriodEndDate);
                        DateFilter := GetFilter("Date Filter"); // NAVCZ
                        UpdateSubForm;
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = VAT;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        SetFilter("Date Filter", DateFilter);
                        CurrPage.Update;
                        // NAVCZ
                        if DateFilter <> '' then begin
                            VATPeriodStartDate := 0D;
                            VATPeriodEndDate := 0D;
                        end;
                        // NAVCZ
                        UpdateSubForm();
                    end;
                }
                field(DateRowFilter; DateRowFilter)
                {
                    ApplicationArea = VAT;
                    Caption = 'Date Row Filter';
                    ToolTip = 'Specifies the date row filter for VAT entries.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        // NAVCZ
                        if DateRowFilter <> '' then begin
                            FilterTokens.MakeDateFilter(DateRowFilter);
                            SetFilter("Date Row Filter", DateRowFilter);
                        end else
                            SetRange("Date Row Filter");
                        // NAVCZ
                        UpdateSubForm;
                    end;
                }
                field(CountryCodeFillFiter; CountryCodeFillFiter)
                {
                    ApplicationArea = VAT;
                    Caption = 'Performance Country';
                    TableRelation = "Country/Region";
                    ToolTip = 'Specifies performance country code for VAT entries filtr.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(SettlementNoFilter; SettlementNoFilter)
                {
                    ApplicationArea = VAT;
                    Caption = 'Filter VAT Settlement No.';
                    ToolTip = 'Specifies the filter setup of document number which the VAT entries were closed.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Open,Closed,Open and Closed';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if Selection = Selection::"Open and Closed" then
                            OpenandClosedSelectionOnValida;
                        if Selection = Selection::Closed then
                            ClosedSelectionOnValidate;
                        if Selection = Selection::Open then
                            OpenSelectionOnValidate;
                    end;
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Before and Within Period,Within Period';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            BeforeandWithinPeriodSelection;
                        if PeriodSelection = PeriodSelection::"Within Period" then
                            WithinPeriodPeriodSelectionOnV;
                    end;
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies that the VAT Statement Preview window shows amounts in the additional reporting currency.';

                    trigger OnValidate()
                    begin
                        UseAmtsInAddCurrOnPush;
                    end;
                }
            }
            part(VATStatementLineSubForm; "VAT Statement Preview Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                              "Statement Name" = FIELD(Name);
                SubPageView = SORTING("Statement Template Name", "Statement Name", "Line No.");
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
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm;
    end;

    trigger OnOpenPage()
    begin
        // NAVCZ
        if DateRowFilter <> '' then
            SetFilter("Date Row Filter", DateRowFilter);
        if (VATPeriodStartDate <> 0D) or (VATPeriodEndDate <> 0D) then begin
            SetRange("Date Filter", VATPeriodStartDate, VATPeriodEndDate);
            DateFilter := GetFilter("Date Filter");
        end else
            // NAVCZ
            DateFilter := '';
        UpdateSubForm;
    end;

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        UseAmtsInAddCurr: Boolean;
        DateFilter: Text[30];
        VATPeriod: Record "VAT Period";
        VATPeriodStartDate: Date;
        VATPeriodEndDate: Date;
        SettlementNoFilter: Text[50];
        CountryCodeFillFiter: Code[10];
        DateRowFilter: Text[30];

    procedure UpdateSubForm()
    begin
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, UseAmtsInAddCurr,
          SettlementNoFilter, CountryCodeFillFiter); // NAVCZ
    end;

    local procedure OpenandClosedSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure ClosedSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure OpenSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure BeforeandWithinPeriodSelOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure WithinPeriodPeriodSelectOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure UseAmtsInAddCurrOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure OpenSelectionOnValidate()
    begin
        OpenSelectionOnPush;
    end;

    local procedure ClosedSelectionOnValidate()
    begin
        ClosedSelectionOnPush;
    end;

    local procedure OpenandClosedSelectionOnValida()
    begin
        OpenandClosedSelectionOnPush;
    end;

    local procedure WithinPeriodPeriodSelectionOnV()
    begin
        WithinPeriodPeriodSelectOnPush;
    end;

    local procedure BeforeandWithinPeriodSelection()
    begin
        BeforeandWithinPeriodSelOnPush;
    end;
}

