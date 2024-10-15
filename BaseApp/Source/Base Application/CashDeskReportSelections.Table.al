table 11759 "Cash Desk Report Selections"
{
    Caption = 'Cash Desk Report Selections';

    fields
    {
        field(1; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'C.Rcpt,C.Wdrwl,P.C.Rcpt,P.C.Wdrwl';
            OptionMembers = "C.Rcpt","C.Wdrwl","P.C.Rcpt","P.C.Wdrwl";
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CashDeskReportSelections: Record "Cash Desk Report Selections";

    [Scope('OnPrem')]
    procedure NewRecord()
    begin
        CashDeskReportSelections.SetRange(Usage, Usage);
        if CashDeskReportSelections.FindLast and (CashDeskReportSelections.Sequence <> '') then
            Sequence := IncStr(CashDeskReportSelections.Sequence)
        else
            Sequence := '1';
    end;
}

