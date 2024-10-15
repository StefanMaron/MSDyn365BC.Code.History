table 253 "G/L Entry - VAT Entry Link"
{
    Caption = 'G/L Entry - VAT Entry Link';
    Permissions = TableData "G/L Entry - VAT Entry Link" = rimd;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry"."Entry No.";
        }
        field(2; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "G/L Entry No.", "VAT Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertLink(GLEntryNo: Integer; VATEntryNo: Integer)
    var
        GLEntryVatEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVatEntryLink.InsertLinkSelf(GLEntryNo, VATEntryNo);
    end;

    procedure InsertLinkSelf(GLEntryNo: Integer; VATEntryNo: Integer)
    begin
        Init();
        "G/L Entry No." := GLEntryNo;
        "VAT Entry No." := VATEntryNo;
        Insert();
    end;

    procedure InsertLinkWithGLAccountSelf(GLEntryNo: Integer; VATEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATEntryEdit: Codeunit "VAT Entry - Edit";
    begin
        InsertLinkSelf(GLEntryNo, VATEntryNo);

        if GLEntryNo <> 0 then begin
            GLEntry.SetLoadFields("G/L Account No.");
            GLEntry.Get(GLEntryNo);
            VATEntryEdit.SetGLAccountNo("VAT Entry No.", GLEntry."G/L Account No.");
        end
    end;
}

