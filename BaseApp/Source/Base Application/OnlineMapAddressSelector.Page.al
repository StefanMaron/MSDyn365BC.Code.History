page 802 "Online Map Address Selector"
{
    Caption = 'Online Map Address Selector';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LookupSelection; LookupSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Selection';
                    OptionCaption = ' ,Bank,Contact,Customer,Employee,Job,Location,Resource,Vendor,Ship-to Address,Order Address';

                    trigger OnValidate()
                    begin
                        LookupSelectionOnAfterValidate;
                    end;
                }
                field(LookupCode; LookupCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lookup Code';
                    ToolTip = 'Specifies a list of contact, customer, or location codes to choose from.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectedRecPosition := LoadLocationLookup(SelectedTableNo, LookupCode, true);
                    end;

                    trigger OnValidate()
                    begin
                        SelectedRecPosition := LoadLocationLookup(SelectedTableNo, LookupCode, false);
                    end;
                }
                field(Distance; Distance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Distance In';
                    OptionCaption = 'Miles,Kilometers';
                    ToolTip = 'Specifies if distances on the online map are shown in miles or kilometers.';
                }
                field(Route; Route)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Route';
                    OptionCaption = 'Quickest,Shortest';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        OnlineMapSetup.Get();
        Distance := OnlineMapSetup."Distance In";
        Route := OnlineMapSetup.Route;
    end;

    var
        OnlineMapSetup: Record "Online Map Setup";
        SelectedRecPosition: Text[1000];
        LookupCode: Code[20];
        LookupSelection: Option " ",Bank,Contact,Customer,Employee,Job,Location,Resource,Vendor,"Ship-to Address","Order Address";
        Text001: Label 'The selection that was chosen is not valid.';
        Text003: Label 'The value %1 from Table ID %2 could not be found.';
        Distance: Option Miles,Kilometers;
        Route: Option Quickest,Shortest;
        SelectedTableNo: Integer;
        Text004: Label 'Table No. %1 is not set up.';

    procedure GetTableNo(): Integer
    begin
        exit(SelectedTableNo);
    end;

    procedure GetRecPosition(): Text[1000]
    begin
        exit(SelectedRecPosition);
    end;

    procedure SetTableNo()
    var
        IsHandled: Boolean;
    begin
        case LookupSelection of
            LookupSelection::" ":
                SelectedTableNo := 0;
            LookupSelection::Bank:
                SelectedTableNo := DATABASE::"Bank Account";
            LookupSelection::Contact:
                SelectedTableNo := DATABASE::Contact;
            LookupSelection::Customer:
                SelectedTableNo := DATABASE::Customer;
            LookupSelection::Employee:
                SelectedTableNo := DATABASE::Employee;
            LookupSelection::Job:
                SelectedTableNo := DATABASE::Job;
            LookupSelection::Location:
                SelectedTableNo := DATABASE::Location;
            LookupSelection::Resource:
                SelectedTableNo := DATABASE::Resource;
            LookupSelection::Vendor:
                SelectedTableNo := DATABASE::Vendor;
            LookupSelection::"Ship-to Address":
                SelectedTableNo := DATABASE::"Ship-to Address";
            LookupSelection::"Order Address":
                SelectedTableNo := DATABASE::"Order Address";
            else begin
                    IsHandled := false;
                    OnSetTableNoElseCase(LookupSelection, SelectedTableNo, IsHandled);
                    if not IsHandled then
                        Error(Text001);
                end;
        end;
    end;

    local procedure LoadLocationLookup(LoadTableNo: Integer; var LookupCode: Code[20]; Lookup: Boolean): Text[1000]
    var
        SelectedRecPosition: Text;
        IsHandled: Boolean;
    begin
        case LoadTableNo of
            DATABASE::"Bank Account":
                exit(LoadBankAccount(LookupCode, Lookup));
            DATABASE::Contact:
                exit(LoadContact(LookupCode, Lookup));
            DATABASE::Customer:
                exit(LoadCustomer(LookupCode, Lookup));
            DATABASE::Employee:
                exit(LoadEmployee(LookupCode, Lookup));
            DATABASE::Job:
                exit(LoadJob(LookupCode, Lookup));
            DATABASE::Location:
                exit(LoadLocation(LookupCode, Lookup));
            DATABASE::Resource:
                exit(LoadResource(LookupCode, Lookup));
            DATABASE::Vendor:
                exit(LoadVendor(LookupCode, Lookup));
            DATABASE::"Ship-to Address":
                exit(LoadShipTo(LookupCode, Lookup));
            DATABASE::"Order Address":
                exit(LoadOrderAddress(LookupCode, Lookup));
            else begin
                    OnLoadLocationLookupElseCase(LoadTableNo, LookupCode, Lookup, SelectedRecPosition, IsHandled);
                    if IsHandled then
                        exit(SelectedRecPosition);

                    Error(Text004, Format(LoadTableNo));
                end;
        end;
    end;

    local procedure LoadBankAccount(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        BankAccount: Record "Bank Account";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Bank Account List", BankAccount) = ACTION::LookupOK
        else
            Response := BankAccount.Get(LookUpCode);

        if Response then begin
            LookUpCode := BankAccount."No.";
            exit(BankAccount.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::"Bank Account");
    end;

    local procedure LoadContact(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Contact: Record Contact;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Contact List", Contact) = ACTION::LookupOK
        else
            Response := Contact.Get(LookUpCode);

        if Response then begin
            LookUpCode := Contact."No.";
            exit(Contact.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Contact);
    end;

    local procedure LoadCustomer(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Customer: Record Customer;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Customer List", Customer) = ACTION::LookupOK
        else
            Response := Customer.Get(LookUpCode);

        if Response then begin
            LookUpCode := Customer."No.";
            exit(Customer.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Customer);
    end;

    local procedure LoadEmployee(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Employee: Record Employee;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Employee List", Employee) = ACTION::LookupOK
        else
            Response := Employee.Get(LookUpCode);

        if Response then begin
            LookUpCode := Employee."No.";
            exit(Employee.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Employee);
    end;

    local procedure LoadJob(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Job: Record Job;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Job List", Job) = ACTION::LookupOK
        else
            Response := Job.Get(LookUpCode);

        if Response then begin
            LookUpCode := Job."No.";
            exit(Job.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Job);
    end;

    local procedure LoadLocation(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Location: Record Location;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Location List", Location) = ACTION::LookupOK
        else
            Response := Location.Get(LookUpCode);

        if Response then begin
            LookUpCode := Location.Code;
            exit(Location.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Location);
    end;

    local procedure LoadResource(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Resource: Record Resource;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Resource List", Resource) = ACTION::LookupOK
        else
            Response := Resource.Get(LookUpCode);

        if Response then begin
            LookUpCode := Resource."No.";
            exit(Resource.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Resource);
    end;

    local procedure LoadVendor(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Vendor: Record Vendor;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Vendor List", Vendor) = ACTION::LookupOK
        else
            Response := Vendor.Get(LookUpCode);

        if Response then begin
            LookUpCode := Vendor."No.";
            exit(Vendor.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::Vendor);
    end;

    local procedure LoadShipTo(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        ShipToAddress: Record "Ship-to Address";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Ship-to Address List", ShipToAddress) = ACTION::LookupOK
        else
            Response := ShipToAddress.Get(LookUpCode);

        if Response then begin
            LookUpCode := ShipToAddress.Code;
            exit(ShipToAddress.GetPosition);
        end;
        Error(Text003, LookUpCode, DATABASE::"Ship-to Address");
    end;

    local procedure LoadOrderAddress(var LookupCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        OrderAddress: Record "Order Address";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Order Address List", OrderAddress) = ACTION::LookupOK
        else
            Response := OrderAddress.Get(LookupCode);

        if Response then begin
            LookupCode := OrderAddress.Code;
            exit(OrderAddress.GetPosition);
        end;
        Error(Text003, LookupCode, DATABASE::"Order Address");
    end;

    procedure Getdefaults(var ActualDistance: Option Miles,Kilometers; var ActualRoute: Option Quickest,Shortest)
    begin
        ActualDistance := Distance;
        ActualRoute := Route;
    end;

    local procedure LookupSelectionOnAfterValidate()
    begin
        SetTableNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadLocationLookupElseCase(LoadTableNo: Integer; var LookupCode: Code[20]; Lookup: Boolean; var SelectedRecPosition: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetTableNoElseCase(LookupSelection: Option; var SelectedTableNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

