page 20291 "Available Use Case Events"
{
    Caption = 'Available Events';
    PageType = List;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    SourceTableTemporary = true;
    SourceTable = "Use Case Event";
    SourceTableView = SORTING(Enable) ORDER(Descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Enable; Enable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether event is enabled for usage.';
                }
                field(Name; Description)
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the event.';
                }
            }
        }
    }

    procedure GetEventBuffer(var NewTempUseCaseEvent: Record "Use Case Event" Temporary);
    begin
        NewTempUseCaseEvent.DeleteAll();
        TempUseCaseEvent.Reset();
        if TempUseCaseEvent.FindSet() then
            repeat
                NewTempUseCaseEvent.Init();
                NewTempUseCaseEvent := TempUseCaseEvent;
                NewTempUseCaseEvent.Insert();
            until TempUseCaseEvent.Next() = 0;
    end;

    procedure SetEventBuffer(var NewTempUseCaseEvent: Record "Use Case Event" Temporary);
    begin
        NewTempUseCaseEvent.Reset();
        if NewTempUseCaseEvent.FindSet() then
            repeat
                TempUseCaseEvent.Init();
                TempUseCaseEvent := NewTempUseCaseEvent;
                TempUseCaseEvent.Insert();
            until NewTempUseCaseEvent.Next() = 0;
    end;

    trigger OnOpenPage();
    begin
        TempUseCaseEvent.Reset();
        if TempUseCaseEvent.FindSet() then
            repeat
                Init();
                Rec := TempUseCaseEvent;
                Insert();
            until TempUseCaseEvent.Next() = 0;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean;
    begin
        TempUseCaseEvent.Reset();
        TempUseCaseEvent.DeleteAll();
        Reset();
        if FindSet() then
            repeat
                TempUseCaseEvent.Init();
                TempUseCaseEvent := Rec;
                TempUseCaseEvent.Insert();
            until Next() = 0;
    end;

    var
        TempUseCaseEvent: Record "Use Case Event" temporary;
}