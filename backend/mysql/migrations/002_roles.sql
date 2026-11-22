-- Apply if the earlier three-role schema has already been created.
alter table profiles modify role enum('customer','kos_owner','admin','app_owner') not null;
