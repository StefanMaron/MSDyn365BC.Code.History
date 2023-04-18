table 2154 "O365 Payment Method"
{
    Caption = 'O365 Payment Method';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure RefreshRecords()
    var
        PaymentMethod: Record "Payment Method";
        PreviousPaymentMethodCode: Code[10];
    begin
        PreviousPaymentMethodCode := Code;
        DeleteAll();
        PaymentMethod.SetRange("Use for Invoicing", true);
        if PaymentMethod.FindSet() then
            repeat
                Code := PaymentMethod.Code;
                Description := PaymentMethod.GetDescriptionInCurrentLanguage();
                if Insert() then;
            until PaymentMethod.Next() = 0;
        if Get(PreviousPaymentMethodCode) then;
    end;
#endif
}


