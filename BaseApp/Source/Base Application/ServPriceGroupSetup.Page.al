page 6081 "Serv. Price Group Setup"
{
    Caption = 'Serv. Price Group Setup';
    DataCaptionExpression = FormCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Serv. Price Group Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Price Group Code"; "Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the Service Price Adjustment Group that was assigned to the service item linked to this service line.';
                    Visible = ServicePriceGroupCodeVisible;
                }
                field("Fault Area Code"; "Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the fault area assigned to the given service price group.';
                }
                field("Cust. Price Group Code"; "Cust. Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the customer price group associated with the given service price group.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code assigned to the service price group.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service hours become applicable to the service price group.';
                }
                field("Serv. Price Adjmt. Gr. Code"; "Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
                }
                field("Include Discounts"; "Include Discounts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that any sales line or invoice discount set up for the customer will be deducted from the price of the item assigned to the service price group.';
                }
                field("Adjustment Type"; "Adjustment Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the adjustment type for the service item line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount to which the price on the service price group is going to be adjusted.';
                }
                field("Include VAT"; "Include VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the amount to be adjusted for the given service price group should include VAT.';
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

    trigger OnInit()
    begin
        ServicePriceGroupCodeVisible := true;
    end;

    trigger OnOpenPage()
    var
        ServPriceGroup: Record "Service Price Group";
        ShowColumn: Boolean;
    begin
        ShowColumn := true;
        if GetFilter("Service Price Group Code") <> '' then
            if ServPriceGroup.Get("Service Price Group Code") then
                ShowColumn := false
            else
                Reset;
        ServicePriceGroupCodeVisible := ShowColumn;
    end;

    var
        [InDataSet]
        ServicePriceGroupCodeVisible: Boolean;

    local procedure FormCaption(): Text[180]
    var
        ServicePriceGroup: Record "Service Price Group";
    begin
        if GetFilter("Service Price Group Code") <> '' then
            if ServicePriceGroup.Get("Service Price Group Code") then
                exit(StrSubstNo('%1 %2', "Service Price Group Code", ServicePriceGroup.Description));
    end;
}

