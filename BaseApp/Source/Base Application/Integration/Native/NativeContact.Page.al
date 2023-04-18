#if not CLEAN20
page 2803 "Native - Contact"
{
    Caption = 'Native - Contact';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = Contact;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(xrmId; "Xrm Id")
                {
                    ApplicationArea = All;
                    Caption = 'xrmId', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;
                }
                field(email; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;
                }
                field(customerId; CustomerID)
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;
                    ToolTip = 'Specifies the Customer Id.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearCalculatedFields();
        SetCustomerID();
    end;

    trigger OnOpenPage()
    begin
        SetFilterForGETStatement();
        SelectLatestVersion();
    end;

    var
        CustomerID: Guid;

    local procedure SetCustomerID()
    var
        Customer: Record Customer;
    begin
        CustomerID := Customer.SystemId;
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(CustomerID);
        Clear("Xrm Id");
    end;

    local procedure SetFilterForGETStatement()
    var
        Contact: Record Contact;
        xrmIDFilter: Text[250];
    begin
        xrmIDFilter := CopyStr(GetFilter("Xrm Id"), 1, MaxStrLen(xrmIDFilter));
        if xrmIDFilter = '' then
            exit;

        SetRange("No.", Contact."No.");

        SetRange("Xrm Id");
    end;

    [ServiceEnabled]
    procedure MakeCustomer(var ActionContext: DotNet WebServiceActionContext)
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid(CustomerID) then
            Customer.GetBySystemId(CustomerID);

        SetActionResponse(ActionContext, Customer);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; var Customer: Record Customer)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(Customer.FieldNo(SystemId), Customer.SystemId);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Customer Entity")
    end;
}
#endif
