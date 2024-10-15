page 12117 "Before Start Item Cost"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Before Start Item Cost';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Before Start Item Cost";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the item costs before you began using Microsoft Dynamics NAV in your organization.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item that was entered in the Item Card window.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard unit of measure that was used to track the item in inventory before you began using Microsoft Dynamics NAV.';
                }
                field("Purchase Quantity"; "Purchase Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that was purchased before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Purchase Amount"; "Purchase Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the items purchased before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Production Quantity"; "Production Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of an item that was in production before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Production Amount"; "Production Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of an item that was in production before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Direct Components Amount"; "Direct Components Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost of the item, based on the component costs before you began using Microsoft Dynamics NAV.';
                }
                field("Direct Routing Amount"; "Direct Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost associated with the routing of an item before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Overhead Routing Amount"; "Overhead Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overhead cost associated with the routing of an item before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Subcontracted Amount"; "Subcontracted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item costs associated with outsourcing operations to a subcontractor before you began using Microsoft Dynamics NAV.';
                }
            }
        }
    }

    actions
    {
    }
}

