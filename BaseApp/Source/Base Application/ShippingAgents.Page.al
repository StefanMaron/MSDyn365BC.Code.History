page 428 "Shipping Agents"
{
    AdditionalSearchTerms = 'transportation,carrier';
    ApplicationArea = Suite;
    Caption = 'Shipping Agents';
    PageType = List;
    SourceTable = "Shipping Agent";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a shipping agent code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the shipping agent.';
                }
                field("Internet Address"; "Internet Address")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an Internet address for the shipping agent.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the account number that the shipping agent has assigned to your company.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ShippingAgentServices)
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping A&gent Services';
                    Image = CheckList;
                    RunObject = Page "Shipping Agent Services";
                    RunPageLink = "Shipping Agent Code" = FIELD(Code);
                    ToolTip = 'View the types of services that your shipping agent can offer you and their shipping time.';
                }
            }
        }
    }
}

