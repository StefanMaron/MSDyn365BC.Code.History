table 31121 "EET Business Premises"
{
    Caption = 'EET Business Premises';
#if CLEAN18
    ObsoleteState = Removed;
#else
    LookupPageID = "EET Business Premises";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(15; Identification; Code[6])
        {
            Caption = 'Identification';
            Numeric = true;
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
#if not CLEAN18
            TableRelation = "Certificate CZ Code";
#endif
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN18
    trigger OnDelete()
    var
        EETEntry: Record "EET Entry";
        EETCashRegister: Record "EET Cash Register";
    begin
        EETEntry.SetCurrentKey("Business Premises Code", "Cash Register Code");
        EETEntry.SetRange("Business Premises Code", Code);
        if not EETEntry.IsEmpty() then
            Error(EntryExistsErr, TableCaption, Code);

        EETCashRegister.SetRange("Business Premises Code", Code);
        if not EETCashRegister.IsEmpty() then begin
            if GuiAllowed then
                if not Confirm(CashRegExistsQst, false, TableCaption, Code) then
                    Error('');
            EETCashRegister.DeleteAll(true);
        end;
    end;

#endif
    var
        EntryExistsErr: Label 'You cannot delete %1 %2 because there is at least one EET entry.', Comment = '%1 = Table Caption;%2 = Primary Key';
        CashRegExistsQst: Label 'Do you really want to delete %1 %2, even if at least one cash register exists?', Comment = '%1 = Table Caption;%2 = Primary Key';
}

