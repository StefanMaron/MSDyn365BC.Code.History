page 10500 "Postcode Search"
{
    Caption = 'Postcode Search';
    DataCaptionExpression = '';
    PageType = StandardDialog;
    SourceTable = "Autocomplete Address";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(PostcodeField; Postcode)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Postcode';
                Lookup = true;
                ShowMandatory = true;
            }
            field(DeliveryPoint; Address)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delivery Point';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        TempFullAutocompleteAddress: Record "Autocomplete Address" temporary;
    begin
        TempFullAutocompleteAddress.Init;
        Rec := TempFullAutocompleteAddress;
        Postcode := AutocompletePostcode;
        Address := AutcompleteDeliveryPoint;
        "Country / Region" := 'GB';
        Insert;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::Cancel then
            exit(true);
    end;

    var
        AutocompletePostcode: Text[20];
        AutcompleteDeliveryPoint: Text[50];

    [Scope('OnPrem')]
    procedure SetValues(NewPostcode: Text[20]; NewDeliveryPoint: Text[50])
    begin
        AutocompletePostcode := NewPostcode;
        AutcompleteDeliveryPoint := NewDeliveryPoint;
    end;

    [Scope('OnPrem')]
    procedure GetValues(var ResultPostcode: Text; var ResultDeliveryPoint: Text)
    begin
        ResultPostcode := Postcode;
        ResultDeliveryPoint := Address;
    end;
}

