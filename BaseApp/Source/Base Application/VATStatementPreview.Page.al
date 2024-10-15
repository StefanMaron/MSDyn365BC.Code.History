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
                field(VATPeriod; VATPeriod)
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Period';
                    LookupPageID = "Periodic VAT Settlement List";
                    TableRelation = "Periodic Settlement VAT Entry";
                    ToolTip = 'Specifies the VAT period.';

                    trigger OnValidate()
                    begin
                        if VATPeriod <> '' then begin
                            SetRange("Date Filter");
                            Selection := Selection::Closed;
                            PeriodSelection := PeriodSelection::"Within Period";
                        end;

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
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        SetFilter("Date Filter", DateFilter);
                        UpdateSubForm();
                        CurrPage.Update;
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
        if ValuesPassed then begin
            Selection := PassedSelection;
            PeriodSelection := PassedPeriodSelection;
            DateFilter := PassedDateFilter;
        end else
            DateFilter := '';
        UpdateSubForm;
        PeriodSelection := 1;
    end;

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        VATPeriod: Code[10];
        UseAmtsInAddCurr: Boolean;
        DateFilter: Text[30];
        PassedSelection: Option;
        PassedPeriodSelection: Option;
        PassedDateFilter: Text[30];
        ValuesPassed: Boolean;

    procedure UpdateSubForm()
    begin
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, UseAmtsInAddCurr, VATPeriod);
    end;

    procedure SetParameters(NewSelection: Option; NewPeriodSelection: Option; NewDateFilter: Text[30])
    begin
        PassedSelection := NewSelection;
        PassedPeriodSelection := NewPeriodSelection;
        PassedDateFilter := NewDateFilter;
        ValuesPassed := true;
    end;
    
    local procedure OpenandClosedSelectionOnPush()
    begin
        VATPeriod := '';
        UpdateSubForm;
    end;

    local procedure ClosedSelectionOnPush()
    begin
        "Date Filter" := 0D;
        UpdateSubForm;
    end;

    local procedure OpenSelectionOnPush()
    begin
        VATPeriod := '';
        UpdateSubForm;
    end;

    local procedure BeforeandWithinPeriodSelOnPush()
    begin
        VATPeriod := '';
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

