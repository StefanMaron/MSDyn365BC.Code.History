xmlport 9000 "Export/Import User Groups"
{
    Caption = 'Export/Import User Groups';
    UseRequestPage = false;

    schema
    {
        textelement(UserGroups)
        {
            tableelement("User Group"; "User Group")
            {
                XmlName = 'UserGroup';
                fieldelement(Code; "User Group".Code)
                {
                }
                fieldelement(Name; "User Group".Name)
                {
                }
                fieldelement(DefaultProfile; "User Group"."Default Profile ID")
                {
                }
                tableelement("User Group Permission Set"; "User Group Permission Set")
                {
                    LinkFields = "User Group Code" = FIELD(Code);
                    LinkTable = "User Group";
                    MinOccurs = Zero;
                    XmlName = 'UserGroupPermissionSet';
                    SourceTableView = SORTING("User Group Code", "Role ID", "App ID") ORDER(Ascending);
                    fieldelement(UserGroupCode; "User Group Permission Set"."User Group Code")
                    {
                    }
                    fieldelement(RoleId; "User Group Permission Set"."Role ID")
                    {
                        FieldValidate = no;
                    }
                    fieldelement(Scope; "User Group Permission Set".Scope)
                    {
                    }
                    fieldelement(AppID; "User Group Permission Set"."App ID")
                    {
                        FieldValidate = no;
                    }

                    trigger OnAfterInsertRecord()
                    begin
                        NoOfUserGroupPermissionSetsInserted += 1;
                    end;

                    trigger OnBeforeInsertRecord()
                    var
                        UserGroupPermissionSet: Record "User Group Permission Set";
                        AggregatePermissionSet: Record "Aggregate Permission Set";
                    begin
                        if UserGroupPermissionSet.Get(
                             "User Group Permission Set"."User Group Code",
                             "User Group Permission Set"."Role ID", "User Group Permission Set".Scope, "User Group Permission Set"."App ID")
                        then
                            currXMLport.Skip;
                        if not AggregatePermissionSet.Get(
                             "User Group Permission Set".Scope,
                             "User Group Permission Set"."App ID",
                             "User Group Permission Set"."Role ID")
                        then
                            currXMLport.Skip;
                    end;
                }

                trigger OnAfterInsertRecord()
                begin
                    NoOfUserGroupsInserted += 1;
                end;

                trigger OnBeforeInsertRecord()
                var
                    UserGroup: Record "User Group";
                begin
                    IsImport := true;
                    if UserGroup.Get("User Group".Code) then
                        currXMLport.Skip;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    begin
        if IsImport then
            Message(InsertedMsg, NoOfUserGroupsInserted, NoOfUserGroupPermissionSetsInserted);
    end;

    var
        IsImport: Boolean;
        NoOfUserGroupsInserted: Integer;
        NoOfUserGroupPermissionSetsInserted: Integer;
        InsertedMsg: Label '%1 user groups with a total of %2 user group permission sets were inserted.', Comment = '%1 and %2 are numbers/quantities.';
}

