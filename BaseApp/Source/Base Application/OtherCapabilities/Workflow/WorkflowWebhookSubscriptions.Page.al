page 831 "Workflow Webhook Subscriptions"
{
    Caption = 'workflowWebhookSubscriptions', Locked = true;
    PageType = List;
    SourceTable = "Workflow Webhook Subscription";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(notificationUrl; NotificationURLTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Notification Url', Locked = true;
                    ToolTip = 'Specifies the notification url to post to.';

                    trigger OnValidate()
                    begin
                        // runs on inserting new entry into the table
                        // entry comes as base64 encoded string but need to be stored as BLOB
                        SetNotificationUrl(NotificationURLTxt);
                    end;
                }
                field(conditions; ConditionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Conditions', Locked = true;
                    ToolTip = 'Specifies the workflow conditions.';

                    trigger OnValidate()
                    begin
                        // runs on inserting new entry into the table
                        // entry comes as base64 encoded string but need to be stored as BLOB
                        SetConditions(ConditionsTxt);
                    end;
                }
                field(eventCode; "Event Code")
                {
                    ApplicationArea = All;
                    Caption = 'Event Code', Locked = true;
                    ToolTip = 'Specifies the event code for the workflow.';
                }
                field(clientType; "Client Type")
                {
                    ApplicationArea = All;
                    Caption = 'Client Type', Locked = true;
                    ToolTip = 'Specifies the client type';
                }
                field(clientId; "Client Id")
                {
                    ApplicationArea = All;
                    Caption = 'Client Id', Locked = true;
                    ToolTip = 'Specifies the id for the client from Power Automate.';
                }
                field(enabled; Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled', Locked = true;
                    ToolTip = 'Specifies if the subscription is enabled.';
                }
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    ToolTip = 'Specifies the unique identifier for a subscription.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        // runs on get record
        // need to return encoded string
        ConditionsTxt := GetConditions();
        NotificationURLTxt := GetNotificationUrl();
    end;

    var
        ConditionsTxt: Text;
        NotificationURLTxt: Text;
}

