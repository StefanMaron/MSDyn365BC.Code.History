page 10502 "Postcode Service Lookup"
{
    Caption = 'Postal code service selection';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the service to automatically insert post codes, such as GetAdress.io.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        // Add Disabled option
        PostcodeServiceManager.RegisterService(Rec, DisabledLbl, DisabledLbl);
        PostcodeServiceManager.DiscoverPostcodeServices(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        IsSuccessful: Boolean;
    begin
        if CloseAction = ACTION::LookupCancel then
            exit(true);

        // Get selection
        CurrPage.SetSelectionFilter(TempNameValueBuffer);
        SetFilter(ID, TempNameValueBuffer.GetFilter(ID));
        FindFirst();
        TempNameValueBuffer := Rec;

        if TempNameValueBuffer.Value = DisabledLbl then
            exit(true);

        PostcodeServiceManager.ShowConfigurationPage(TempNameValueBuffer.Value, IsSuccessful);

        exit(IsSuccessful);
    end;

    var
        DisabledLbl: Label 'Disabled';
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
}

