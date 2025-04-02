// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12461 "Posted Service Shipments IT" extends "Posted Service Shipments"
{
    actions
    {
        addafter("&Navigate")
        {
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServiceShptUpdate: Page "Posted Service Shpt. - Update";
                begin
                    PostedServiceShptUpdate.LookupMode := true;
                    PostedServiceShptUpdate.SetRec(Rec);
                    PostedServiceShptUpdate.RunModal();
                end;
            }
        }
        addafter("&Print_Promoted")
        {
            actionref("Update Document_Promoted"; "Update Document")
            {
            }
        }
    }
}
