table 362 "ECSL VAT Report Line"
{
    Caption = 'ECSL VAT Report Line';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Report No."; Code[20])
        {
            Caption = 'Report No.';
            TableRelation = "VAT Report Header"."No.";
        }
        field(3; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
        }
        field(4; "Customer VAT Reg. No."; Text[20])
        {
            Caption = 'Customer VAT Reg. No.';
        }
        field(5; "Total Value Of Supplies"; Decimal)
        {
            Caption = 'Total Value Of Supplies';
        }
        field(6; "Transaction Indicator"; Option)
        {
            Caption = 'Transaction Indicator';
            OptionCaption = 'B2B Goods,,Triangulated Goods,B2B Services';
            OptionMembers = "B2B Goods",,"Triangulated Goods","B2B Services";
        }
        field(10500; "Line Status"; Option)
        {
            CalcFormula = Lookup ("GovTalk Message Parts".Status WHERE("Report No." = FIELD("Report No."),
                                                                       "Part Id" = FIELD("XML Part Id"),
                                                                       "VAT Report Config. Code" = CONST("EC Sales List")));
            Caption = 'Line Status';
            FieldClass = FlowField;
            OptionCaption = ' ,Released,Submitted,Accepted,Rejected';
            OptionMembers = " ",Released,Submitted,Accepted,Rejected;
        }
        field(10501; "XML Part Id"; Guid)
        {
            Caption = 'XML Part Id';
        }
    }

    keys
    {
        key(Key1; "Report No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ClearLines(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        ECSLVATReportLineRelation.DeleteAll;
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.DeleteAll;
    end;
}

