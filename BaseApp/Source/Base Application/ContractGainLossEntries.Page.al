page 6064 "Contract Gain/Loss Entries"
{
    Caption = 'Contract Gain/Loss Entries';
    DataCaptionFields = "Contract No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Contract Gain/Loss Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the contract number linked to this contract gain/loss entry.';
                }
                field("Contract Group Code"; "Contract Group Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the contract group code linked to this contract gain/loss entry.';
                }
                field("Change Date"; "Change Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the change on the service contract occurred.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Type of Change"; "Type of Change")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the type of change on the service contract.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the customer number that is linked to this contract gain/loss entry.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the change in annual amount on the service contract.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

