page 5361 "Integration Field Mapping List"
{
    Caption = 'Integration Field Mapping List';
    DataCaptionExpression = "Integration Table Mapping Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Integration Field Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if field synchronization is enabled or disabled.';
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of the field in Dynamics 365.';
                }
                field(FieldName; NAVFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in Business Central.';
                }
                field("Integration Table Field No."; "Integration Table Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of the field in Dynamics 365 Sales.';
                }
                field(IntegrationFieldName; CRMFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in Dynamics 365 Sales.';
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the direction of the synchronization.';
                }
                field("Constant Value"; "Constant Value")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the constant value that the mapped field will be set to.';
                }
                field("Transformation Rule"; "Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a rule for transforming imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365.';
                }
                field("Transformation Direction"; "Transformation Direction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direction of the transformation.';
                    Editable = "Direction" = "Direction"::Bidirectional;
                }
                field("Validate Field"; "Validate Field")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the field should be validated during assignment in Business Central. ';
                }
                field("Validate Integration Table Fld"; "Validate Integration Table Fld")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the integration field should be validated during assignment in Dynamics 365 Sales.';
                }
                field("Clear Value on Failed Sync"; "Clear Value on Failed Sync")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the field value should be cleared in case of integration error during assignment in Dynamics 365 Sales.';
                }
                field("Not Null"; "Not Null")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the data transfer should be skipped for destination fields whose new value is going to be null. This is only applicable for GUID fields, such as OwnerId, that must not be changed to null during synchronization.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetTransformationRules)
            {
                ApplicationArea = Suite;
                Caption = 'Reset Transformation Rules';
                Image = ResetStatus;
                ToolTip = 'Resets the transformation rules for the integration table mapping.';

                trigger OnAction()
                var
                    IntegrationFieldMapping: Record "Integration Field Mapping";
                begin
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec."Integration Table Mapping Name");
                    IntegrationFieldMapping.ModifyAll("Transformation Rule", '');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetFieldCaptions;
    end;

    var
        TypeHelper: Codeunit "Type Helper";
        NAVFieldName: Text;
        CRMFieldName: Text;

    local procedure GetFieldCaptions()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get("Integration Table Mapping Name");
        NAVFieldName := GetFieldCaption(IntegrationTableMapping."Table ID", "Field No.");
        CRMFieldName := GetFieldCaption(IntegrationTableMapping."Integration Table ID", "Integration Table Field No.");
    end;

    local procedure GetFieldCaption(TableID: Integer; FieldID: Integer): Text
    var
        "Field": Record "Field";
    begin
        if (TableID <> 0) and (FieldID <> 0) then
            if TypeHelper.GetField(TableID, FieldID, Field) then
                exit(Field."Field Caption");
        exit('');
    end;
}

