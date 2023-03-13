page 700 "Error Messages"
{
    Caption = 'Error Messages';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Error Message";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Message Type", ID)
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the message is an error, a warning, or information.';
                }
                field(Description; Rec."Message")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    DrillDown = true;
                    Enabled = EnableOpenRelatedEntity;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the message.';
                }
                field(Context; Format(Rec."Context Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context';
                    ToolTip = 'Specifies the context record.';
                    trigger OnDrillDown()
                    begin
                        HandleDrillDown(Rec.FieldNo("Context Record ID"));
                    end;
                }
                field("Context Field Name"; Rec."Context Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Context Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field(Source; Format(Rec."Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the record source of the error.';

                    trigger OnDrillDown()
                    begin
                        HandleDrillDown(Rec.FieldNo("Record ID"));
                    end;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Field Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the field where the error occurred.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies more information than the information shown in the Description field.';
                }
                field("Support Url"; Rec."Support Url")
                {
                    Caption = 'Support URL';
                    ApplicationArea = Invoicing, Basic, Suite;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the URL of an external web site that offers additional support.';
                }
                field(CallStack; CallStack)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Call Stack';
                    ToolTip = 'Specifies the call stack where the error occurred.';

                    trigger OnDrillDown()
                    begin
                        ShowErrorCallStack();
                    end;
                }
                field(TimeOfError; Rec."Created On")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time of Error';
                    ToolTip = 'The time of error occurence.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Related Record';
                Enabled = EnableOpenRelatedEntity;
                Image = View;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    OnOpenRelatedRecord(Rec, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun("Record ID");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenRelatedRecord_Promoted; OpenRelatedRecord)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableActions();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
        CallStack := Rec.GetErrorCallStack();
    end;

    var
        PageManagement: Codeunit "Page Management";
        [InDataSet]
        StyleText: Text[20];
        CallStack: Text;
        EnableOpenRelatedEntity: Boolean;
        ErrorContextNotFoundErr: Label 'Error context not found: %1', Comment = '%1 - Record Id';

    procedure SetRecords(var TempErrorMessage: Record "Error Message" temporary)
    begin
        if TempErrorMessage.FindFirst() then;
        if TempErrorMessage.IsTemporary then
            Copy(TempErrorMessage, true)
        else
            TempErrorMessage.CopyToTemp(Rec);
    end;

    local procedure SetStyle()
    begin
        case Rec."Message Type" of
            Rec."Message Type"::Error:
                StyleText := 'Attention';
            Rec."Message Type"::Warning,
          Rec."Message Type"::Information:
                StyleText := 'None';
        end;
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := "Record ID";
        EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

    local procedure HandleDrillDown(SourceFieldNo: Integer)
    var
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnDrillDownSource(Rec, SourceFieldNo, IsHandled);
        if not IsHandled then
            case SourceFieldNo of
                FieldNo("Context Record ID"):
                    begin
                        if not RecRef.Get("Context Record ID") then
                            error(ErrorContextNotFoundErr, Format("Context Record ID"));
                        PageManagement.PageRunAtField("Context Record ID", "Context Field Number", false);
                    end;
                FieldNo("Record ID"):
                    if IsDimSetEntryInconsistency() then
                        RunDimSetEntriesPage()
                    else
                        PageManagement.PageRunAtField("Record ID", "Field Number", false);
            end
    end;

    local procedure IsDimSetEntryInconsistency(): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        RecId: RecordId;
    begin
        RecId := "Record ID";
        exit((RecId.TableNo = Database::"Dimension Set Entry") and ("Field Number" = DimensionSetEntry.FieldNo("Global Dimension No.")));
    end;

    local procedure RunDimSetEntriesPage()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntries: Page "Dimension Set Entries";
    begin
        DimensionSetEntry.Get("Record ID");
        DimensionSetEntries.SetRecord(DimensionSetEntry);
        DimensionSetEntries.SetUpdDimSetGlblDimNoVisible();
        DimensionSetEntries.Run();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownSource(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;
}

