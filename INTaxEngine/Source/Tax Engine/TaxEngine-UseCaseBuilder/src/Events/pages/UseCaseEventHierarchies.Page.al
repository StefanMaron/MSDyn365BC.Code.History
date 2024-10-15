page 20294 "Use Case Event Hierarchies"
{
    Caption = 'Event Hierarchies';
    Editable = false;
    PageType = ListPart;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTable = "Use Case Event Relation";
    SourceTableView = sorting(Sequence);
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Event Name"; "Event Name")
                {
                    Visible = False;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of event.';
                }
                field("Use Case Name"; "Use Case Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use Case';
                    ToolTip = 'Specifies the name of the use case.';
                    trigger OnDrillDown();
                    var
                        UseCaseCard: Page "Use Case Card";
                    begin
                        UseCase.GET("Case ID");
                        UseCaseCard.SETRECORD(UseCase);
                        UseCaseCard.Run();
                    end;
                }
                field(Enable; EnabledTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    Editable = false;
                    StyleExpr = true;
                    Style = Subordinate;
                    ToolTip = 'Specifies whether use case is enabled for usage.';
                    trigger OnAssistEdit()
                    var
                        TaxUseCaseEvent: Record "Use Case Event";
                        BlankTableRelationErr: Label 'You must specify Table Relation.';
                    begin
                        if Enabled then
                            Enabled := false
                        else begin
                            TaxUseCaseEvent.Get("Event Name");
                            UseCase.Get("Case ID");
                            if (UseCase."Tax Table ID" <> TaxUseCaseEvent."Table ID") and (UseCaseObjectHelper.IsTableRelationEmpty("Case ID", "Table Relation ID")) then
                                Error(BlankTableRelationErr);

                            Enabled := true;
                        end;
                        CurrPage.Update(true);
                        FormatLine();
                    end;
                }
                field(TableRelation; TableRelationTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Relation';
                    Editable = false;
                    StyleExpr = true;
                    Style = Subordinate;
                    ToolTip = 'Specifies the table relation between event and use case. if the table on event and use case are same and this should be left blank.';
                    trigger OnAssistEdit()
                    var
                        TaxUseCaseEvents: Record "Use Case Event";
                        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
                    begin
                        TaxUseCaseEvents.Get("Event Name");
                        if TaxUseCaseEvents."Table ID" <> 0 then begin
                            UseCase.Get("Case ID");
                            if IsNullGuid("Table Relation ID") then
                                "Table Relation ID" := UseCaseEntityMgmt.CreateTableLinking("Case ID", UseCase."Tax Table ID", TaxUseCaseEvents."Table ID");
                            Modify();
                            Commit();
                            UseCaseMgmt.OpenTableLinkingDialog("Case ID", "Table Relation ID");
                        end;
                        FormatLine();
                    end;
                }
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sequence of execution for use cases.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TableRelation2)
            {
                Caption = 'Table Relation';
                ApplicationArea = Basic, Suite;
                Image = SuggestTables;
                ToolTip = 'Specifies the table relation between event and use case. if the table on event and use case are same and this should be left blank.';
                trigger OnAction()
                var
                    TaxUseCaseEvents: Record "Use Case Event";
                    UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
                begin
                    TaxUseCaseEvents.Get("Event Name");
                    if TaxUseCaseEvents."Table ID" <> 0 then begin
                        UseCase.Get("Case ID");
                        if IsNullGuid("Table Relation ID") then
                            "Table Relation ID" := UseCaseEntityMgmt.CreateTableLinking("Case ID", UseCase."Tax Table ID", TaxUseCaseEvents."Table ID");
                        Modify();
                        Commit();
                        UseCaseMgmt.OpenTableLinkingDialog("Case ID", "Table Relation ID");
                    end;
                end;
            }
            action(MoveUp)
            {
                Caption = 'Move Before';
                ApplicationArea = Basic, Suite;
                Image = MoveUp;
                ToolTip = 'Moves the sequencing of execution before previous use case.';
                trigger OnAction()
                begin
                    if Sequence > 0 then begin
                        Sequence -= 1;
                        Modify();
                        Commit();
                    end;

                end;
            }
            action(MoveDown)
            {
                Caption = 'Move After';
                ApplicationArea = Basic, Suite;
                Image = MoveDown;
                ToolTip = 'Moves the sequencing of execution after next use case.';
                trigger OnAction()
                var

                begin
                    Sequence += 1;
                    Modify();
                    Commit();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var

    begin
        FormatLine();
    end;

    trigger OnAfterGetRecord()
    var

    begin
        FormatLine();
    end;

    local procedure FormatLine()
    begin
        if not UseCaseObjectHelper.IsTableRelationEmpty("Case ID", "Table Relation ID") then
            TableRelationTxt := UseCaseSerialization.TableLinkToString("Case ID", "Table Relation ID")
        else
            TableRelationTxt := '< Table Relation >';

        EnabledTxt := StrSubstNo(isEnabledTxt, Enabled);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FormatLine();
    end;

    var
        UseCase: Record "Tax Use Case";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseSerialization: Codeunit "Use Case Serialization";
        UseCaseObjectHelper: Codeunit "Use Case Object Helper";
        isEnabledTxt: Label '%1', Comment = '%1 = shows Yes or No based on enabled of use case.';
        EnabledTxt: Text;
        TableRelationTxt: Text;
        EmptyGuid: Guid;
}