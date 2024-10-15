page 20295 "Use Case Events"
{
    Caption = 'Tax Use Case Events';
    Editable = false;
    PageType = List;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = Basic, Suite;
    SourceTableTemporary = true;
    SourceTable = "Use Case Event";
    SourceTableView = SORTING("Presentation Order") ORDER(Ascending);
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                IndentationColumn = "Indentation";
                IndentationControls = Description;
                ShowAsTree = true;
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the event name.';
                    StyleExpr = DescriptionStyle;
                }
            }
        }
        area(FactBoxes)
        {
            part("Event Hierarchies"; "Use Case Event Hierarchies")
            {
                Caption = 'Attached Use Cases';
                ApplicationArea = Basic, Suite;
                SubPageView = SORTING(Sequence) ORDER(Ascending);
                SubPageLink = "Event Name" = Field(Name);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AttachUseCase)
            {
                Caption = 'Attach / De-Attach Use Case';
                Enabled = Indentation <> 0;
                ApplicationArea = Basic, Suite;
                Image = "Reuse";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Attach or de-attach a use case.';
                trigger OnAction();
                var
                    UseCaseEventHelpers: Codeunit "Use Case Event Helpers";
                begin
                    UseCaseEventHelpers.OpenAvailableUseCases(Rec);
                end;
            }
        }
    }

    local procedure InsertEventBuffer();
    var
        UseCaseEvent: Record "Use Case Event";
        AllObjWithCaption: Record AllObjWithCaption;
        RunningTableID: Integer;
        Level: Integer;
    begin
        Level += 1;
        Rec.Init();
        Rec.Name := 'Generic Events';
        Rec."Table Name" := 'Generic Events';
        Rec.Description := 'Generic Events';
        Rec."Presentation Order" := Level;
        Rec.Indentation := 0;
        Rec."Dummy Event" := true;
        Rec.Insert();
        Level += 1;
        InsertTableEvents(Level, 0, 'Generic Events');

        UseCaseEvent.SetCurrentKey("Table ID");
        UseCaseEvent.SetFilter("Table ID", '<>%1', 0);
        if UseCaseEvent.FindSet() then
            repeat
                if RunningTableID <> UseCaseEvent."Table ID" then begin
                    AllObjWithCaption.Reset();
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                    AllObjWithCaption.SetRange("Object ID", UseCaseEvent."Table ID");
                    AllObjWithCaption.FindFirst();
                    Level += 1;
                    Rec.Init();
                    Rec.Name := AllObjWithCaption."Object Name";
                    Rec."Table Name" := AllObjWithCaption."Object Name";
                    Rec."Presentation Order" := Level;
                    Rec.Indentation := 0;
                    Rec.Description := AllObjWithCaption."Object Name";
                    Rec."Dummy Event" := true;
                    Rec.Insert();
                    Level += 1;
                    InsertTableEvents(Level, UseCaseEvent."Table ID", AllObjWithCaption."Object Name");
                end;
                RunningTableID := UseCaseEvent."Table ID";
            until UseCaseEvent.Next() = 0;
    end;

    local procedure InsertTableEvents(Level: Integer; TableID: Integer; TableName: Text[30]);
    var
        UseCaseEvent: Record "Use Case Event";
    begin
        UseCaseEvent.SetRange("Table ID", TableID);
        if UseCaseEvent.FindSet() then
            repeat
                Rec.Init();
                Rec.Name := UseCaseEvent.Name;
                Rec."Table ID" := UseCaseEvent."Table ID";
                Rec."Table Name" := TableName;
                Rec.Description := UseCaseEvent.Description;
                Rec."Presentation Order" := Level;
                Rec.Indentation := 1;
                Rec.Insert();
            until UseCaseEvent.Next() = 0;
    end;

    trigger OnOpenPage();
    begin
        UseCaseEventHandling.CreateEventsLibrary();
        InsertEventBuffer();
        Reset();
        SetCurrentKey("Presentation Order");
        if FindSet() then;
    end;

    trigger OnAfterGetRecord();
    begin
        if "Dummy Event" then
            DescriptionStyle := 'Strong'
        else
            DescriptionStyle := 'Standard';
    end;

    var
        UseCaseEventHandling: Codeunit "Use Case Event Handling";
        DescriptionStyle: Text;
}