page 9510 "Event Subscriptions"
{
    Caption = 'Event Subscriptions';
    Editable = false;
    PageType = List;
    SourceTable = "Event Subscription";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Subscriber Codeunit ID"; "Subscriber Codeunit ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of codeunit that contains the event subscriber function.';
                }
                field(CodeunitName; CodeunitName)
                {
                    ApplicationArea = All;
                    Caption = 'Subscriber Codeunit Name';
                    ToolTip = 'Specifies the name of the codeunit that contains the event subscriber function.';
                }
                field("Subscriber Function"; "Subscriber Function")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the event subscriber function in the subscriber codeunit that subscribes to the event.';
                }
                field("Event Type"; "Event Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the event type, which can be Business, Integration, or Trigger.';
                }
                field("Publisher Object Type"; "Publisher Object Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of object that contains the event publisher function that publishes the event.';
                }
                field("Publisher Object ID"; "Publisher Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the object that contains the event publisher function that publishes the event.';
                }
                field(PublisherName; PublisherName)
                {
                    ApplicationArea = All;
                    Caption = 'Publisher Object Name';
                    ToolTip = 'Specifies the name of the object that contains the event publisher function that publishes the event.';
                }
                field("Published Function"; "Published Function")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the event publisher function in the publisher object that the event subscriber function subscribes to.';
                }
                field(Active; Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the event subscription is active.';
                }
                field("Number of Calls"; "Number of Calls")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many times the event subscriber function has been called. The event subscriber function is called when the published event is raised in the application.';
                }
                field("Subscriber Instance"; "Subscriber Instance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the event subscription.';
                }
                field("Active Manual Instances"; "Active Manual Instances")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies manual event subscriptions that are active.';
                }
                field("Originating App Name"; "Originating App Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object that triggers the event.';
                }
                field("Error Information"; "Error Information")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an error that occurred for the event subscription.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        AllObj: Record AllObj;
        CodeUnitMetadata: Record "CodeUnit Metadata";
    begin
        if CodeUnitMetadata.Get("Subscriber Codeunit ID") then
            CodeunitName := CodeUnitMetadata.Name;

        AllObj.SetRange("Object Type", "Publisher Object Type");
        AllObj.SetRange("Object ID", "Publisher Object ID");
        if AllObj.FindFirst then
            PublisherName := AllObj."Object Name";
    end;

    var
        CodeunitName: Text;
        PublisherName: Text;
}

