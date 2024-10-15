page 14962 "Payroll Analysis Lines"
{
    AutoSplitKey = true;
    Caption = 'Payroll Analysis Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = Worksheet;
    SourceTable = "Payroll Analysis Line";

    layout
    {
        area(content)
        {
            field(CurrentAnalysisLineTempl; CurrentAnalysisLineTempl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the related record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    PayrollAnalysisReportMgt.LookupAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    PayrollAnalysisReportMgt.CheckAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
                    CurrentAnalysisLineTemplOnAfte;
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field(ElementTypeFilter; ElementTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Type Filter';

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.ValidateFilter(
                          ElementTypeFilter, DATABASE::"Payroll Analysis Line", FieldNo("Element Type Filter"), false);
                        "Element Type Filter" := ElementTypeFilter;
                        PayrollAnalysisReportMgt.ValidateFilter(
                          "Element Type Filter", DATABASE::"Payroll Analysis Line", FieldNo("Element Type Filter"), true);
                    end;
                }
                field("Element Filter"; "Element Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(WorkModeFilter; WorkModeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Work Mode Filter';

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.ValidateFilter(
                          WorkModeFilter, DATABASE::"Payroll Analysis Line", FieldNo("Work Mode Filter"), false);
                        "Work Mode Filter" := WorkModeFilter;
                        PayrollAnalysisReportMgt.ValidateFilter(
                          "Work Mode Filter", DATABASE::"Payroll Analysis Line", FieldNo("Work Mode Filter"), true);
                    end;
                }
                field(DisabilityGroupFilter; DisabilityGroupFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disability Group Filter';

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.ValidateFilter(
                          DisabilityGroupFilter, DATABASE::"Payroll Analysis Line", FieldNo("Disability Group Filter"), false);
                        "Disability Group Filter" := DisabilityGroupFilter;
                        PayrollAnalysisReportMgt.ValidateFilter(
                          "Disability Group Filter", DATABASE::"Payroll Analysis Line", FieldNo("Disability Group Filter"), true);
                    end;
                }
                field(ContractTypeGroupFilter; ContractTypeGroupFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contract Type Filter';

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.ValidateFilter(
                          ContractTypeGroupFilter, DATABASE::"Payroll Analysis Line", FieldNo("Contract Type Filter"), false);
                        "Contract Type Filter" := ContractTypeGroupFilter;
                        PayrollAnalysisReportMgt.ValidateFilter(
                          "Contract Type Filter", DATABASE::"Payroll Analysis Line", FieldNo("Contract Type Filter"), true);
                    end;
                }
                field(PaymentSourceFilter; PaymentSourceFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Source Filter';

                    trigger OnValidate()
                    begin
                        PayrollAnalysisReportMgt.ValidateFilter(
                          PaymentSourceFilter, DATABASE::"Payroll Analysis Line", FieldNo("Payment Source Filter"), false);
                        "Payment Source Filter" := PaymentSourceFilter;
                        PayrollAnalysisReportMgt.ValidateFilter(
                          "Payment Source Filter", DATABASE::"Payroll Analysis Line", FieldNo("Payment Source Filter"), true);
                    end;
                }
                field("Use PF Accum. System Filter"; "Use PF Accum. System Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Base Filter"; "Income Tax Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("New Page"; "New Page")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Show; Show)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Bold; Bold)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                }
                field(Indentation; Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field(Italic; Italic)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Underline; Underline)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Show Opposite Sign"; "Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to show debits in reports as negative amounts with a minus sign and credits as positive amounts.';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert &Payroll Elements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Payroll Elements';
                    Ellipsis = true;
                    Image = BulletList;

                    trigger OnAction()
                    begin
                        InsertLine(0);
                    end;
                }
                action("Insert Payroll Element &Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Payroll Element &Groups';
                    Ellipsis = true;
                    Image = CreateDocuments;

                    trigger OnAction()
                    begin
                        InsertLine(1);
                    end;
                }
                action("Insert &Employees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Employees';
                    Ellipsis = true;
                    Image = NewOpportunity;

                    trigger OnAction()
                    begin
                        InsertLine(2);
                    end;
                }
                action("Insert &Org. Units")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Org. Units';
                    Ellipsis = true;
                    Image = Hierarchy;

                    trigger OnAction()
                    begin
                        InsertLine(3);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        ElementTypeFilter := "Element Type Filter";
        PayrollAnalysisReportMgt.ValidateFilter(
          ElementTypeFilter, DATABASE::"Payroll Analysis Line", FieldNo("Element Type Filter"), false);

        WorkModeFilter := "Work Mode Filter";
        PayrollAnalysisReportMgt.ValidateFilter(
          WorkModeFilter, DATABASE::"Payroll Analysis Line", FieldNo("Work Mode Filter"), false);

        DisabilityGroupFilter := "Disability Group Filter";
        PayrollAnalysisReportMgt.ValidateFilter(
          DisabilityGroupFilter, DATABASE::"Payroll Analysis Line", FieldNo("Disability Group Filter"), false);

        ContractTypeGroupFilter := "Contract Type Filter";
        PayrollAnalysisReportMgt.ValidateFilter(
          ContractTypeGroupFilter, DATABASE::"Payroll Analysis Line", FieldNo("Contract Type Filter"), false);

        PaymentSourceFilter := "Payment Source Filter";
        PayrollAnalysisReportMgt.ValidateFilter(
          PaymentSourceFilter, DATABASE::"Payroll Analysis Line", FieldNo("Payment Source Filter"), false);
        DescriptionOnFormat;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ElementTypeFilter := '';
        WorkModeFilter := '';
        DisabilityGroupFilter := '';
        PaymentSourceFilter := '';
        ContractTypeGroupFilter := '';
    end;

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        PayrollAnalysisReportMgt.OpenAnalysisLines(CurrentAnalysisLineTempl, Rec);

        GLSetup.Get();

        if PayrollAnalysisLineTemplate.Get(CurrentAnalysisLineTempl) then
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code")
            else begin
                Clear(PayrollAnalysisView);
                PayrollAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                PayrollAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        CurrentAnalysisLineTempl: Code[10];
        ElementTypeFilter: Text[150];
        WorkModeFilter: Text[80];
        DisabilityGroupFilter: Text[30];
        ContractTypeGroupFilter: Text[30];
        PaymentSourceFilter: Text[150];
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;

    [Scope('OnPrem')]
    procedure InsertLine(Type: Option "Payroll Element","Payroll Element Group",Employee,"Org. Unit")
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        InsertPayrollAnalysisLine: Codeunit "Insert Payroll Analysis Line";
    begin
        CurrPage.Update(true);
        PayrollAnalysisLine.Copy(Rec);
        if "Line No." = 0 then begin
            PayrollAnalysisLine := xRec;
            if PayrollAnalysisLine.Next() = 0 then
                PayrollAnalysisLine."Line No." := xRec."Line No." + 10000;
        end;
        case Type of
            Type::Employee:
                InsertPayrollAnalysisLine.InsertEmployees(PayrollAnalysisLine);
            Type::"Payroll Element":
                InsertPayrollAnalysisLine.InsertPayrollElements(PayrollAnalysisLine);
            Type::"Payroll Element Group":
                InsertPayrollAnalysisLine.InsertPayrollElementGroups(PayrollAnalysisLine);
            Type::"Org. Unit":
                InsertPayrollAnalysisLine.InsertOrgUnits(PayrollAnalysisLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetCurrentAnalysisLineTempl(AnalysisLineTemlName: Code[10])
    begin
        CurrentAnalysisLineTempl := AnalysisLineTemlName;
    end;

    local procedure CurrentAnalysisLineTemplOnAfte()
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        CurrPage.SaveRecord;
        PayrollAnalysisReportMgt.SetAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
        if PayrollAnalysisLineTemplate.Get(CurrentAnalysisLineTempl) then
            CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionEmphasize := Bold;
        DescriptionIndent := Indentation;
    end;
}

