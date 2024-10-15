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
        area(reporting)
        {
            action(DetailedReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detailed Report';
                Ellipsis = true;
                Image = VATStatement;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                ToolTip = 'View a statement of posted VAT and calculates the duty liable to the customs authorities for the selected period. The report is printed on the basis of the definition of the VAT statement in the VAT Statement Line table. The report can be used in connection with VAT settlement to the customs authorities and for your own documentation.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"VAT Statement")
                end;
            }
            action(FormIntervatDeclaration)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Form/Intervat Declaration';
                Ellipsis = true;
                Image = ExportElectronicDocument;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                RunObject = Report "VAT - Form";
                ToolTip = 'Send monthly or quarterly VAT declarations to an XML file. You can choose to print your VAT declaration and send the printed document to your tax authorities or you can send an electronic VAT declaration via the internet using Intervat. Note: This report is based on the VAT Statement template that is defined in the general ledger setup. Therefore, it may export data that is not the same as what is shown in the VAT Statement Preview window.';
            }
            action(DeclarationSummaryReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Declaration Summary Report';
                Ellipsis = true;
                Image = VATLedger;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                ToolTip = 'View a summary of the VAT declarations for different accounting periods. You can also use the report to verify the amounts in the different VAT rows. For example, you can check if the sum of two rows equals the amount in another row.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"VAT Statement Summary");
                end;
            }
        }
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
    end;

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        UseAmtsInAddCurr: Boolean;
        DateFilter: Text[30];
        PassedSelection: Option;
        PassedPeriodSelection: Option;
        PassedDateFilter: Text[30];
        ValuesPassed: Boolean;

    procedure UpdateSubForm()
    begin
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, UseAmtsInAddCurr);
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

    local procedure RunReport(ReportID: Integer)
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName.SetRange("Statement Template Name", "Statement Template Name");
        VATStatementName.SetRange(Name, Name);
        REPORT.Run(ReportID, true, false, VATStatementName);
    end;
}

