permissionset 566 "Todo - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read to-dos';

    Permissions = tabledata Attendee = R,
                  tabledata "Interaction Template Setup" = R,
                  tabledata "Rlshp. Mgt. Comment Line" = R,
                  tabledata "RM Matrix Management" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata Team = R,
                  tabledata "Team Salesperson" = R,
                  tabledata "To-do" = R,
                  tabledata "To-do Interaction Language" = R;
}
