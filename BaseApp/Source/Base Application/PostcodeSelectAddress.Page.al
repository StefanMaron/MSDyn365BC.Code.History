page 9140 "Postcode Select Address"
{
    Caption = 'Address Selection';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Value; Value)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the postal code.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetAddressList(var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        if TempAddressListNameValueBuffer.FindSet() then
            repeat
                Rec := TempAddressListNameValueBuffer;
                Insert();
            until TempAddressListNameValueBuffer.Next() = 0;

        FindFirst(); // Move selection to the first one
    end;

    procedure GetSelectedAddress(var TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        CurrPage.SetSelectionFilter(TempSelectedAddressNameValueBuffer);
        SetFilter(ID, TempSelectedAddressNameValueBuffer.GetFilter(ID));
        FindFirst();
        TempSelectedAddressNameValueBuffer := Rec;
    end;
}

