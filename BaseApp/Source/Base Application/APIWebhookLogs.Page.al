page 5461 "API Webhook Logs"
{
    APIGroup = 'runtime';
    APIPublisher = 'microsoft';
    Caption = 'webhookLogs', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'webhookLog';
    EntitySetName = 'webhookLogs';
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = ID;
    PageType = API;
    SourceTable = "Activity Log";
    SourceTableView = SORTING("Activity Date")
                      ORDER(Descending)
                      WHERE("Table No Filter" = CONST(2000000095),
                            Context = CONST('APIWEBHOOK'));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(time; "Activity Date")
                {
                    ApplicationArea = All;
                    Caption = 'time', Locked = true;
                    ToolTip = 'Specifies the activity time.';
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    ToolTip = 'Specifies the activity status.';
                }
                field(message; Description)
                {
                    ApplicationArea = All;
                    Caption = 'message', Locked = true;
                    ToolTip = 'Specifies the activity message.';
                }
                field(details; Details)
                {
                    ApplicationArea = All;
                    Caption = 'details', Locked = true;
                    ToolTip = 'Specifies the activity details.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        ContentInStream: InStream;
    begin
        if not "Detailed Info".HasValue then
            Details := "Activity Message"
        else begin
            "Detailed Info".CreateInStream(ContentInStream, TEXTENCODING::UTF8);
            if ContentInStream.EOS then begin
                CalcFields("Detailed Info");
                "Detailed Info".CreateInStream(ContentInStream, TEXTENCODING::UTF8);
            end;
            ContentInStream.Read(Details);
        end
    end;

    trigger OnOpenPage()
    begin
        SetAutoCalcFields("Detailed Info");
    end;

    var
        Details: Text;
}

