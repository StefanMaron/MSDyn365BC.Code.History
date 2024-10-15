xmlport 14960 "Payroll Analysis Reports"
{
    Caption = 'Payroll Analysis Reports';

    schema
    {
        textelement(PayrollAnalysisReports)
        {
            tableelement("Payroll Analysis Report Name"; "Payroll Analysis Report Name")
            {
                XmlName = 'PayrollAnalysisReportName';
                UseTemporary = true;
                fieldelement(Name; "Payroll Analysis Report Name".Name)
                {
                }
                fieldelement(Description; "Payroll Analysis Report Name".Description)
                {
                }
                fieldelement(AnalysisLineTemplateName; "Payroll Analysis Report Name"."Analysis Line Template Name")
                {
                }
                fieldelement(AnalysisColumnTemplateName; "Payroll Analysis Report Name"."Analysis Column Template Name")
                {
                }
            }
            tableelement("Payroll Analysis Line Template"; "Payroll Analysis Line Template")
            {
                XmlName = 'PayrollAnalysisLineTemplate';
                UseTemporary = true;
                fieldelement(Name; "Payroll Analysis Line Template".Name)
                {
                }
                fieldelement(Description; "Payroll Analysis Line Template".Description)
                {
                }
                fieldelement(DefaultColumnTemplateName; "Payroll Analysis Line Template"."Default Column Template Name")
                {
                }
                fieldelement(PayrollAnalysisViewCode; "Payroll Analysis Line Template"."Payroll Analysis View Code")
                {
                }
                tableelement("Payroll Analysis Line"; "Payroll Analysis Line")
                {
                    LinkFields = "Analysis Line Template Name" = FIELD(Name);
                    LinkTable = "Payroll Analysis Line Template";
                    XmlName = 'PayrollAnalysisLine';
                    UseTemporary = true;
                    fieldelement(AnalysisLineTemplateName; "Payroll Analysis Line"."Analysis Line Template Name")
                    {
                    }
                    fieldelement(LineNo; "Payroll Analysis Line"."Line No.")
                    {
                    }
                    fieldelement(RowNo; "Payroll Analysis Line"."Row No.")
                    {
                    }
                    fieldelement(Description; "Payroll Analysis Line".Description)
                    {
                    }
                    fieldelement(Type; "Payroll Analysis Line".Type)
                    {
                    }
                    fieldelement(Expression; "Payroll Analysis Line".Expression)
                    {
                    }
                    fieldelement(NewPage; "Payroll Analysis Line"."New Page")
                    {
                    }
                    fieldelement(Show; "Payroll Analysis Line".Show)
                    {
                    }
                    fieldelement(Bold; "Payroll Analysis Line".Bold)
                    {
                    }
                    fieldelement(Italic; "Payroll Analysis Line".Italic)
                    {
                    }
                    fieldelement(Underline; "Payroll Analysis Line".Underline)
                    {
                    }
                    fieldelement(ShowOppositeSign; "Payroll Analysis Line"."Show Opposite Sign")
                    {
                    }
                    fieldelement(Dimension1Totaling; "Payroll Analysis Line"."Dimension 1 Totaling")
                    {
                    }
                    fieldelement(Dimension2Totaling; "Payroll Analysis Line"."Dimension 2 Totaling")
                    {
                    }
                    fieldelement(Dimension3Totaling; "Payroll Analysis Line"."Dimension 3 Totaling")
                    {
                    }
                    fieldelement(Dimension4Totaling; "Payroll Analysis Line"."Dimension 4 Totaling")
                    {
                    }
                    fieldelement(Indentation; "Payroll Analysis Line".Indentation)
                    {
                    }
                    fieldelement(ElementTypeFilter; "Payroll Analysis Line"."Element Type Filter")
                    {
                    }
                    fieldelement(ElementFilter; "Payroll Analysis Line"."Element Filter")
                    {
                    }
                    fieldelement(UsePFAccumSystemFilter; "Payroll Analysis Line"."Use PF Accum. System Filter")
                    {
                    }
                    fieldelement(IncomeTaxBaseFilter; "Payroll Analysis Line"."Income Tax Base Filter")
                    {
                    }
                    fieldelement(WorkModeFilter; "Payroll Analysis Line"."Work Mode Filter")
                    {
                    }
                    fieldelement(DisabilityGroupFilter; "Payroll Analysis Line"."Disability Group Filter")
                    {
                    }
                    fieldelement(PaymentSourceFilter; "Payroll Analysis Line"."Payment Source Filter")
                    {
                    }
                    fieldelement(ContractTypeFilter; "Payroll Analysis Line"."Contract Type Filter")
                    {
                    }
                    fieldelement(CalcGroupFilter; "Payroll Analysis Line"."Calc Group Filter")
                    {
                    }
                }
            }
            tableelement("Payroll Analysis Column Tmpl."; "Payroll Analysis Column Tmpl.")
            {
                XmlName = 'PayrollAnalysisColumnTmpl';
                UseTemporary = true;
                fieldelement(Name; "Payroll Analysis Column Tmpl.".Name)
                {
                }
                fieldelement(Description; "Payroll Analysis Column Tmpl.".Description)
                {
                }
                tableelement("Payroll Analysis Column"; "Payroll Analysis Column")
                {
                    LinkFields = "Analysis Column Template" = FIELD(Name);
                    LinkTable = "Payroll Analysis Column Tmpl.";
                    XmlName = 'PayrollAnalysisColumn';
                    UseTemporary = true;
                    fieldelement(AnalysisColumnTemplate; "Payroll Analysis Column"."Analysis Column Template")
                    {
                    }
                    fieldelement(LineNo; "Payroll Analysis Column"."Line No.")
                    {
                    }
                    fieldelement(ColumnNo; "Payroll Analysis Column"."Column No.")
                    {
                    }
                    fieldelement(ColumnHeader; "Payroll Analysis Column"."Column Header")
                    {
                    }
                    fieldelement(ColumnType; "Payroll Analysis Column"."Column Type")
                    {
                    }
                    fieldelement(AmountType; "Payroll Analysis Column"."Amount Type")
                    {
                    }
                    fieldelement(Formula; "Payroll Analysis Column".Formula)
                    {
                    }
                    fieldelement(ComparisonDateFormula; "Payroll Analysis Column"."Comparison Date Formula")
                    {
                    }
                    fieldelement(ShowOppositeSign; "Payroll Analysis Column"."Show Opposite Sign")
                    {
                    }
                    fieldelement(Show; "Payroll Analysis Column".Show)
                    {
                    }
                    fieldelement(RoundingFactor; "Payroll Analysis Column"."Rounding Factor")
                    {
                    }
                    fieldelement(ComparisonPeriodFormula; "Payroll Analysis Column"."Comparison Period Formula")
                    {
                    }
                }
            }
            tableelement("Payroll Analysis View"; "Payroll Analysis View")
            {
                XmlName = 'PayrollAnalysisView';
                UseTemporary = true;
                fieldelement(Code; "Payroll Analysis View".Code)
                {
                }
                fieldelement(Name; "Payroll Analysis View".Name)
                {
                }
                fieldelement(UpdateOnPosting; "Payroll Analysis View"."Update on Posting")
                {
                }
                fieldelement(Blocked; "Payroll Analysis View".Blocked)
                {
                }
                fieldelement(PayrollElementFilter; "Payroll Analysis View"."Payroll Element Filter")
                {
                }
                fieldelement(EmployeeFilter; "Payroll Analysis View"."Employee Filter")
                {
                }
                fieldelement(StartingDate; "Payroll Analysis View"."Starting Date")
                {
                }
                fieldelement(DateCompression; "Payroll Analysis View"."Date Compression")
                {
                }
                fieldelement(Dimension1Code; "Payroll Analysis View"."Dimension 1 Code")
                {
                }
                fieldelement(Dimension2Code; "Payroll Analysis View"."Dimension 2 Code")
                {
                }
                fieldelement(Dimension3Code; "Payroll Analysis View"."Dimension 3 Code")
                {
                }
                fieldelement(Dimension4Code; "Payroll Analysis View"."Dimension 4 Code")
                {
                }
                fieldelement(RefreshWhenUnblocked; "Payroll Analysis View"."Refresh When Unblocked")
                {
                }
                tableelement("Payroll Analysis View Filter"; "Payroll Analysis View Filter")
                {
                    LinkFields = "Analysis View Code" = FIELD(Code);
                    LinkTable = "Payroll Analysis View";
                    XmlName = 'PayrollAnalysisViewFilter';
                    UseTemporary = true;
                    fieldelement(AnalysisViewCode; "Payroll Analysis View Filter"."Analysis View Code")
                    {
                    }
                    fieldelement(DimensionCode; "Payroll Analysis View Filter"."Dimension Code")
                    {
                    }
                    fieldelement(DimensionValueFilter; "Payroll Analysis View Filter"."Dimension Value Filter")
                    {
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumnTmpl: Record "Payroll Analysis Column Tmpl.";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewFilter: Record "Payroll Analysis View Filter";

    [Scope('OnPrem')]
    procedure SetData(var TempPayrollAnalysisReportName: Record "Payroll Analysis Report Name")
    begin
        if TempPayrollAnalysisReportName.FindSet then
            repeat
                "Payroll Analysis Report Name" := TempPayrollAnalysisReportName;
                "Payroll Analysis Report Name".Insert();

                if not "Payroll Analysis Line Template".Get(TempPayrollAnalysisReportName."Analysis Line Template Name") then
                    if PayrollAnalysisLineTemplate.Get(TempPayrollAnalysisReportName."Analysis Line Template Name") then begin
                        "Payroll Analysis Line Template" := PayrollAnalysisLineTemplate;
                        "Payroll Analysis Line Template".Insert();

                        PayrollAnalysisLine.SetRange("Analysis Line Template Name", PayrollAnalysisLineTemplate.Name);
                        if PayrollAnalysisLine.FindSet then
                            repeat
                                "Payroll Analysis Line" := PayrollAnalysisLine;
                                "Payroll Analysis Line".Insert();
                            until PayrollAnalysisLine.Next = 0;

                        if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                            if not "Payroll Analysis View".Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code") then
                                if PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code") then begin
                                    "Payroll Analysis View" := PayrollAnalysisView;
                                    "Payroll Analysis View".Insert();

                                    PayrollAnalysisViewFilter.SetRange("Analysis View Code", PayrollAnalysisView.Code);
                                    if PayrollAnalysisViewFilter.FindSet then
                                        repeat
                                            "Payroll Analysis View Filter" := PayrollAnalysisViewFilter;
                                            "Payroll Analysis View Filter".Insert();
                                        until PayrollAnalysisViewFilter.Next = 0;
                                end;
                    end;

                if not "Payroll Analysis Column Tmpl.".Get(TempPayrollAnalysisReportName."Analysis Column Template Name") then
                    if PayrollAnalysisColumnTmpl.Get(TempPayrollAnalysisReportName."Analysis Column Template Name") then begin
                        "Payroll Analysis Column Tmpl." := PayrollAnalysisColumnTmpl;
                        "Payroll Analysis Column Tmpl.".Insert();

                        PayrollAnalysisColumn.SetRange("Analysis Column Template", PayrollAnalysisColumnTmpl.Name);
                        if PayrollAnalysisColumn.FindSet then
                            repeat
                                "Payroll Analysis Column" := PayrollAnalysisColumn;
                                "Payroll Analysis Column".Insert();
                            until PayrollAnalysisColumn.Next = 0;
                    end;
            until TempPayrollAnalysisReportName.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        with "Payroll Analysis Report Name" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisReportName := "Payroll Analysis Report Name";
                    if PayrollAnalysisReportName.Find then begin
                        PayrollAnalysisReportName.Delete(true);
                        PayrollAnalysisReportName := "Payroll Analysis Report Name";
                    end;
                    PayrollAnalysisReportName.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis Line Template" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisLineTemplate := "Payroll Analysis Line Template";
                    if PayrollAnalysisLineTemplate.Find then begin
                        PayrollAnalysisLineTemplate.Delete(true);
                        PayrollAnalysisLineTemplate := "Payroll Analysis Line Template";
                    end;
                    PayrollAnalysisLineTemplate.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis Line" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisLine := "Payroll Analysis Line";
                    if PayrollAnalysisLine.Find then begin
                        PayrollAnalysisLine.Delete(true);
                        PayrollAnalysisLine := "Payroll Analysis Line";
                    end;
                    PayrollAnalysisLine.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis Column Tmpl." do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisColumnTmpl := "Payroll Analysis Column Tmpl.";
                    if PayrollAnalysisColumnTmpl.Find then begin
                        PayrollAnalysisColumnTmpl.Delete(true);
                        PayrollAnalysisColumnTmpl := "Payroll Analysis Column Tmpl.";
                    end;
                    PayrollAnalysisColumnTmpl.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis Column" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisColumn := "Payroll Analysis Column";
                    if PayrollAnalysisColumn.Find then begin
                        PayrollAnalysisColumn.Delete(true);
                        PayrollAnalysisColumn := "Payroll Analysis Column";
                    end;
                    PayrollAnalysisColumn.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis View" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisView := "Payroll Analysis View";
                    if PayrollAnalysisView.Find then begin
                        PayrollAnalysisView.Delete(true);
                        PayrollAnalysisView := "Payroll Analysis View";
                    end;
                    PayrollAnalysisView.Insert();
                until Next = 0;
        end;

        with "Payroll Analysis View Filter" do begin
            Reset;
            if FindSet then
                repeat
                    PayrollAnalysisViewFilter := "Payroll Analysis View Filter";
                    if PayrollAnalysisViewFilter.Find then begin
                        PayrollAnalysisViewFilter.Delete(true);
                        PayrollAnalysisViewFilter := "Payroll Analysis View Filter";
                    end;
                    PayrollAnalysisViewFilter.Insert();
                until Next = 0;
        end;
    end;
}

