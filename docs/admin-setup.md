# Assigning the MikroTekos administrator role

Do this only for an account you control.

1. Open account.html on the deployed site and create your account.
2. Confirm your email and sign in once.
3. In Supabase Dashboard, open project zikos → SQL Editor.
4. Replace YOUR_LOGIN_EMAIL@example.com below with the exact email used for your account, then run:

    update auth.users
    set raw_app_meta_data =
      coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'admin')
    where lower(email) = lower('YOUR_LOGIN_EMAIL@example.com');

5. Confirm the query updated exactly one row. Sign out and sign in again so the refreshed session token includes the new app metadata.
6. Open admin.html. The admin inbox should now show service requests and permit status updates.

Do not use raw_user_meta_data or user_metadata for admin authorization: users can edit that metadata themselves. This update is deliberately not automated by the public website.
