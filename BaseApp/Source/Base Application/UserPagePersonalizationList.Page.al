page 9191 "User Page Personalization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Page Personalizations';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Metadata";
    SourceTableTemporary = true;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'delete user personalization'; // "Delete User Personalization" is the old name of the page

    layout
    {
        area(content)
        {
            repeater(Control1106000000)
            {
                ShowCaption = false;
                field("User SID"; "User SID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User SID';
                    ToolTip = 'Specifies the security identifier (SID) of the user who did the personalization.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user ID of the user who performed the personalization.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been personalized.';
                }
                field(Description; PageName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the Name of the page that has been personalized.';
                }
                field("Legacy Personalization"; LegacyPersonalization)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Legacy Personalization';
                    ToolTip = 'Specifies if the personalization was made in the Windows client or the Web client.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date of the personalization.';
                    Visible = false;
                }
                field(Time; Time)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time';
                    ToolTip = 'Specifies the timestamp for the personalization.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PageDefinition: Record "Page Metadata";
    begin
        if "Personalization ID" = 'EXTENSION METADATA' then
            LegacyPersonalization := false
        else
            LegacyPersonalization := true;

        if PageDefinition.Get("Page ID") then
            PageName := PageDefinition.Caption
        else
            PageName := '';
    end;

    trigger OnDeleteRecord(): Boolean
    var
        UserPageMetadata: Record "User Page Metadata";
        UserMetadata: Record "User Metadata";
    begin
        if "Personalization ID" = 'EXTENSION METADATA' then begin
            UserPageMetadata.SetFilter("User SID", "User SID");
            UserPageMetadata.SetFilter("Page ID", Format("Page ID"));

            if UserPageMetadata.FindFirst then
                UserPageMetadata.Delete(true);
        end else begin
            UserMetadata.SetFilter("User SID", "User SID");
            UserMetadata.SetFilter("Page ID", Format("Page ID"));
            UserMetadata.SetFilter("Personalization ID", "Personalization ID");

            if UserMetadata.FindFirst then
                UserMetadata.Delete(true);
        end;

        CurrPage.Update(true);
    end;

    trigger OnOpenPage()
    var
        UserMetadata: Record "User Metadata";
        UserPageMetadata: Record "User Page Metadata";
        EmptyGuid: Guid;
    begin
        Reset;

        if not (FilterUserID = EmptyGuid) then begin
            UserMetadata.SetFilter("User SID", FilterUserID);
            UserPageMetadata.SetFilter("User SID", FilterUserID);
        end;

        if UserMetadata.FindSet then
            repeat
                "User SID" := UserMetadata."User SID";
                "Page ID" := UserMetadata."Page ID";
                "Personalization ID" := UserMetadata."Personalization ID";
                Date := UserMetadata.Date;
                Time := UserMetadata.Time;
                Insert;
            until UserMetadata.Next = 0;

        if UserPageMetadata.FindSet then
            repeat
                "User SID" := UserPageMetadata."User SID";
                "Page ID" := UserPageMetadata."Page ID";
                "Personalization ID" := 'EXTENSION METADATA';
                Insert;
            until UserPageMetadata.Next = 0;
    end;

    var
        LegacyPersonalization: Boolean;
        PageName: Text;
        FilterUserID: Guid;

    procedure SetUserID(UserID: Guid)
    begin
        FilterUserID := UserID;
    end;
}

