xmlport 17401 "Payroll Calc. Group"
{
    Caption = 'Payroll Calc. Group';

    schema
    {
        textelement(PayrollCalcGroups)
        {
            tableelement("Payroll Calc Group"; "Payroll Calc Group")
            {
                XmlName = 'PayrollCalcGroup';
                UseTemporary = true;
                fieldelement(Code; "Payroll Calc Group".Code)
                {
                }
                fieldelement(Name; "Payroll Calc Group".Name)
                {
                    MinOccurs = Zero;
                }
                fieldelement(DisabledPersons; "Payroll Calc Group"."Disabled Persons")
                {
                    MinOccurs = Zero;
                }
                fieldelement(Type; "Payroll Calc Group".Type)
                {
                    MinOccurs = Zero;
                }
                tableelement("Payroll Calc Group Line"; "Payroll Calc Group Line")
                {
                    LinkFields = "Payroll Calc Group" = FIELD(Code);
                    LinkTable = "Payroll Calc Group";
                    MinOccurs = Zero;
                    XmlName = 'PayrollCalcGroupLine';
                    UseTemporary = true;
                    fieldelement(PayrollCalcGroup; "Payroll Calc Group Line"."Payroll Calc Group")
                    {
                    }
                    fieldelement(LineNo; "Payroll Calc Group Line"."Line No.")
                    {
                    }
                    fieldelement(PayrollCalcTypeCode; "Payroll Calc Group Line"."Payroll Calc Type")
                    {
                        MinOccurs = Zero;
                    }
                }
            }
            tableelement("Payroll Calc Type"; "Payroll Calc Type")
            {
                MinOccurs = Zero;
                XmlName = 'PayrollCalcType';
                UseTemporary = true;
                fieldelement(Code; "Payroll Calc Type".Code)
                {
                }
                fieldelement(Description; "Payroll Calc Type".Description)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Priority; "Payroll Calc Type".Priority)
                {
                    MinOccurs = Zero;
                }
                fieldelement(UseInCalc; "Payroll Calc Type"."Use in Calc")
                {
                    MinOccurs = Zero;
                }
                tableelement("Payroll Calc Type Line"; "Payroll Calc Type Line")
                {
                    LinkFields = "Calc Type Code" = FIELD(Code);
                    LinkTable = "Payroll Calc Type";
                    MinOccurs = Zero;
                    XmlName = 'PayrollCalcTypeLine';
                    UseTemporary = true;
                    fieldelement(CalcTypeCode; "Payroll Calc Type Line"."Calc Type Code")
                    {
                    }
                    fieldelement(LineNo; "Payroll Calc Type Line"."Line No.")
                    {
                    }
                    fieldelement(ElementCode; "Payroll Calc Type Line"."Element Code")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Activity; "Payroll Calc Type Line".Activity)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(PayrollPostingGroup; "Payroll Calc Type Line"."Payroll Posting Group")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Calculate; "Payroll Calc Type Line".Calculate)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ElementType; "Payroll Calc Type Line"."Element Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ElementName; "Payroll Calc Type Line"."Element Name")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(GenPostType; "Payroll Calc Type Line"."Posting Type")
                    {
                        MinOccurs = Zero;
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
        PayrollCalcGroup: Record "Payroll Calc Group";
        PayrollCalcGroupLine: Record "Payroll Calc Group Line";
        PayrollCalcType: Record "Payroll Calc Type";
        PayrollCalcTypeLine: Record "Payroll Calc Type Line";

    [Scope('OnPrem')]
    procedure SetData(var SourcePayrollCalcGroup: Record "Payroll Calc Group")
    begin
        if SourcePayrollCalcGroup.FindSet then
            repeat
                "Payroll Calc Group" := SourcePayrollCalcGroup;
                "Payroll Calc Group".Insert();

                PayrollCalcGroupLine.SetRange("Payroll Calc Group", "Payroll Calc Group".Code);
                if PayrollCalcGroupLine.FindSet then
                    repeat
                        "Payroll Calc Group Line" := PayrollCalcGroupLine;
                        "Payroll Calc Group Line".Insert();

                        if PayrollCalcType.Get("Payroll Calc Group Line"."Payroll Calc Type") then
                            if not "Payroll Calc Type".Get("Payroll Calc Group Line"."Payroll Calc Type") then begin
                                "Payroll Calc Type" := PayrollCalcType;
                                "Payroll Calc Type".Insert();

                                PayrollCalcTypeLine.SetRange("Calc Type Code", "Payroll Calc Type".Code);
                                if PayrollCalcTypeLine.FindSet then
                                    repeat
                                        "Payroll Calc Type Line" := PayrollCalcTypeLine;
                                        "Payroll Calc Type Line".Insert();
                                    until PayrollCalcTypeLine.Next() = 0;
                            end;
                    until PayrollCalcGroupLine.Next() = 0;
            until SourcePayrollCalcGroup.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Payroll Calc Group".Reset();
        if "Payroll Calc Group".FindSet then
            repeat
                if PayrollCalcGroup.Get("Payroll Calc Group".Code) then
                    PayrollCalcGroup.Delete(true);
                PayrollCalcGroup := "Payroll Calc Group";
                PayrollCalcGroup.Insert();
            until "Payroll Calc Group".Next() = 0;

        "Payroll Calc Group Line".Reset();
        if "Payroll Calc Group Line".FindSet then
            repeat
                if PayrollCalcGroupLine.Get(
                     "Payroll Calc Group Line"."Payroll Calc Group",
                     "Payroll Calc Group Line"."Line No.")
                then
                    PayrollCalcGroupLine.Delete(true);
                PayrollCalcGroupLine := "Payroll Calc Group Line";
                PayrollCalcGroupLine.Insert();
            until "Payroll Calc Group Line".Next() = 0;

        "Payroll Calc Type".Reset();
        if "Payroll Calc Type".FindSet then
            repeat
                if PayrollCalcType.Get("Payroll Calc Type".Code) then
                    PayrollCalcType.Delete(true);
                PayrollCalcType := "Payroll Calc Type";
                PayrollCalcType.Insert();
            until "Payroll Calc Type".Next() = 0;

        "Payroll Calc Type Line".Reset();
        if "Payroll Calc Type Line".FindSet then
            repeat
                if PayrollCalcTypeLine.Get(
                     "Payroll Calc Type Line"."Calc Type Code",
                     "Payroll Calc Type Line"."Line No.")
                then
                    PayrollCalcTypeLine.Delete(true);
                PayrollCalcTypeLine := "Payroll Calc Type Line";
                PayrollCalcTypeLine.Insert();
            until "Payroll Calc Type Line".Next() = 0;
    end;
}

