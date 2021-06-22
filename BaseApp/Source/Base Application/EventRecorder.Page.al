page 9845 "Event Recorder"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Event Recorder';
    Editable = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Record Events';
    SourceTable = "Recorded Event Buffer";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Call Order")
                      ORDER(Ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'All Recorded Events';
                Editable = false;
                field(CallOrder; "Call Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Call Order';
                    ToolTip = 'Specifies the order in which the events are called.';
                }
                field(EventType; "Event Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Type';
                    StyleExpr = EventTypeStyleExpr;
                    ToolTip = 'Specifies the type of the event that is called.';
                }
                field(HitCount; "Hit Count")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hit Count';
                    ToolTip = 'Specifies the number of time this event is called consecutively.';
                }
                field(ObjectType; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Type';
                    ToolTip = 'Specifies the type of object that contains the called event.';
                }
                field(ObjectID; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    HideValue = ("Object ID" = 0);
                    LookupPageID = "All Objects with Caption";
                    ToolTip = 'Specifies the ID of the object that contains the called event.';
                    Visible = false;
                }
                field(ObjectName; "Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the object that contains the called event.';
                }
                field(EventName; "Event Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event Name';
                    ToolTip = 'Specifies the name of the called event.';
                }
                field(ElementName; "Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Name';
                    ToolTip = 'Specifies the name of the element in which the event is called.';
                }
                field(CallingObjectType; "Calling Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object Type';
                    HideValue = ("Calling Object Type" = 0);
                    ToolTip = 'Specifies the type of the object that calls the event.';
                }
                field(CallingObjectID; "Calling Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object ID';
                    HideValue = ("Calling Object ID" = 0);
                    ToolTip = 'Specifies the ID of the object that calls the event.';
                    Visible = false;
                }
                field(CallingObjectName; "Calling Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Object Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the object that calls the event.';
                }
                field(CallingMethod; "Calling Method")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calling Method';
                    ToolTip = 'Specifies the name of method that calls the event.';
                }
                field(GetALSnippet; GetAlSnippetLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Get AL Snippet';
                    ToolTip = 'Specifies the AL snippet to subscribe to this event.';

                    trigger OnDrillDown()
                    begin
                        Message(DisplaySnippet);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Recording)
            {
                Caption = 'Record Events';
                action(Start)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start';
                    Enabled = NOT EventLoggingRunning;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Start recording UI activities to generate the list of events that are called. The new recording will erase any events that have previously been recorded.';

                    trigger OnAction()
                    begin
                        if not Confirm(StartRecordingQst) then
                            exit;

                        // Delete events from the current table.
                        DeleteAll();

                        LogRecordedEvents.Start;
                        EventLoggingRunning := true;
                    end;
                }
                action(Stop)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Stop';
                    Enabled = EventLoggingRunning;
                    Image = Stop;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Stop recording and generate the list of events that are recorded.';

                    trigger OnAction()
                    begin
                        EventLoggingRunning := false;
                        LogRecordedEvents.Stop(TempRecordedEventBuffer);

                        if TempRecordedEventBuffer.Count = 0 then begin
                            Message(NoEventsRecordedMsg);
                            exit;
                        end;

                        if not Confirm(AddRecordingQst, false, TempRecordedEventBuffer.Count) then
                            exit;

                        // Add elements to the source table of the page to display them in the repeater.
                        if TempRecordedEventBuffer.FindSet then begin
                            repeat
                                Init;
                                Rec := TempRecordedEventBuffer;
                                Insert;
                            until TempRecordedEventBuffer.Next = 0;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "Event Type" = "Event Type"::"Custom Event" then
            EventTypeStyleExpr := 'Attention'
        else
            EventTypeStyleExpr := 'AttentionAccent';
    end;

    var
        TempRecordedEventBuffer: Record "Recorded Event Buffer" temporary;
        LogRecordedEvents: Codeunit "Log Recorded Events";
        AddRecordingQst: Label '%1 events have been recorded. Do you want to display them?', Comment = '%1 represents the number of events recorded.';
        StartRecordingQst: Label 'Do you want to start the recording now?';
        NoEventsRecordedMsg: Label 'No events have been recorded.';
        GetAlSnippetLbl: Label 'Get AL Snippet.';
        EventLoggingRunning: Boolean;
        [InDataSet]
        EventTypeStyleExpr: Text;

    local procedure DisplaySnippet() Snippet: Text
    var
        ObjectTypeForId: Text[30];
    begin
        // In AL, the ID of a table is accessed as Database::MyTable.
        if "Object Type" = "Object Type"::Table then
            ObjectTypeForId := 'Database'
        else
            ObjectTypeForId := GetObjectType("Object Type");

        Snippet := '[EventSubscriber(ObjectType::' + GetObjectType("Object Type") + ', ' +
          ObjectTypeForId + '::' + '"' + "Object Name" + '"' + ', ' +
          '''' + "Event Name" + '''' + ', ' +
          '''' + "Element Name" + '''' + ', ' +
          'true, true)] ' + '\' +
          'local procedure MyProcedure()\' +
          'begin\' +
          'end;\';
    end;

    local procedure GetObjectType(objectType: Option "Object Type"): Text
    begin
        // In AL, the object type is always in English.
        case objectType of
            "Object Type"::Codeunit:
                exit('Codeunit');
            "Object Type"::Page:
                exit('Page');
            "Object Type"::Query:
                exit('Query');
            "Object Type"::Report:
                exit('Report');
            "Object Type"::Table:
                exit('Table');
            "Object Type"::XMLport:
                exit('XmlPort');
        end;
    end;
}

