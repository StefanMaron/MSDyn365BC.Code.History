table 2154 "O365 Payment Method"
{
    Caption = 'O365 Payment Method';
    ReplicateData = false;

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

    procedure RefreshRecords()
    var
        PaymentMethod: Record "Payment Method";
        PreviousPaymentMethodCode: Code[10];
    begin
        PreviousPaymentMethodCode := Code;
        DeleteAll();
        PaymentMethod.SetRange("Use for Invoicing", true);
        if PaymentMethod.FindSet then
            repeat
                Code := PaymentMethod.Code;
                Description := PaymentMethod.GetDescriptionInCurrentLanguage;
                if Insert() then;
            until PaymentMethod.Next = 0;
        if Get(PreviousPaymentMethodCode) then;
    end;
}

