table 31042 "FA Extended Posting Group"
{
    Caption = 'FA Extended Posting Group';
    ObsoleteState = Removed;
    ObsoleteTag = '21.0';
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';

    fields
    {
        field(1; "FA Posting Group Code"; Code[20])
        {
            Caption = 'FA Posting Group Code';
            TableRelation = "FA Posting Group";
        }
        field(2; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Disposal,Maintenance';
            OptionMembers = " ",Disposal,Maintenance;
        }
        field(3; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = if ("FA Posting Type" = const(Disposal)) "Reason Code"
            else
            if ("FA Posting Type" = const(Maintenance)) Maintenance;
        }
        field(4; "Book Val. Acc. on Disp. (Gain)"; Code[20])
        {
            Caption = 'Book Val. Acc. on Disp. (Gain)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Book Val. Acc. on Disp. (Gain)", false);
            end;
        }
        field(5; "Book Val. Acc. on Disp. (Loss)"; Code[20])
        {
            Caption = 'Book Val. Acc. on Disp. (Loss)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Book Val. Acc. on Disp. (Loss)", false);
            end;
        }
        field(6; "Maintenance Expense Account"; Code[20])
        {
            Caption = 'Maintenance Expense Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Maintenance Expense Account", false);
            end;
        }
        field(7; "Maintenance Bal. Acc."; Code[20])
        {
            Caption = 'Maintenance Bal. Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Maintenance Bal. Acc.", true);
            end;
        }
        field(8; "Allocated Book Value % (Gain)"; Decimal)
        {
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field("FA Posting Group Code"),
                                                                    "Allocation Type" = const("Book Value (Gain)"),
                                                                    "Reason/Maintenance Code" = field(Code)));
            Caption = 'Allocated Book Value % (Gain)';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Allocated Book Value % (Loss)"; Decimal)
        {
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field("FA Posting Group Code"),
                                                                    "Allocation Type" = const("Book Value (Loss)"),
                                                                    "Reason/Maintenance Code" = field(Code)));
            Caption = 'Allocated Book Value % (Loss)';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Allocated Maintenance %"; Decimal)
        {
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field("FA Posting Group Code"),
                                                                    "Allocation Type" = const(Maintenance),
                                                                    "Reason/Maintenance Code" = field(Code)));
            Caption = 'Allocated Maintenance %';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31040; "Sales Acc. On Disp. (Gain)"; Code[20])
        {
            Caption = 'Sales Acc. On Disp. (Gain)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Acc. On Disp. (Gain)", false);
            end;
        }
        field(31042; "Sales Acc. On Disp. (Loss)"; Code[20])
        {
            Caption = 'Sales Acc. On Disp. (Loss)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Acc. On Disp. (Loss)", false);
            end;
        }
    }

    keys
    {
        key(Key1; "FA Posting Group Code", "FA Posting Type", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CheckGLAcc(AccNo: Code[20]; DirectPosting: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            if DirectPosting then
                GLAcc.TestField("Direct Posting");
        end;
    end;
}
