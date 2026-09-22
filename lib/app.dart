part of 'main.dart';

class StayNearApp extends StatefulWidget {
  const StayNearApp({this.backend, this.initializationError, super.key});
  final FirebaseBackend? backend;
  final Object? initializationError;
  @override
  State<StayNearApp> createState() => _StayNearAppState();
}

class _StayNearAppState extends State<StayNearApp> with _AddRoomFlow {
  UserRole role = UserRole.landlord;
  AppPage page = AppPage.auth;
  bool login = true;
  String? selectedListingId;
  AppPage listingOrigin = AppPage.boarderHome;
  AppPage editListingOrigin = AppPage.landlordDashboard;
  @override
  UserProfile? activeUser;
  late final backend = widget.backend ?? FirebaseBackend();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  bool _authBusy = false;
  int _authRequest = 0;
  bool _emailVerificationSent = false;

  void _requireFirebaseConfiguration() {
    final error = widget.initializationError;
    if (error != null) throw error;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initializationError != null) return;
    _authSubscription = backend.auth.authStateChanges().listen((user) {
      if (!_authBusy) _restoreSession(user);
    }, onError: _reportError);
  }

  void _reportError(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messenger.currentState?.showSnackBar(
        SnackBar(content: Text(backendMessage(error))),
      );
    });
  }

  Future<void> _restoreSession(User? user) async {
    final request = ++_authRequest;
    if (user == null) {
      _activate(null);
      return;
    }
    try {
      await backend.synchronizeAuthenticatedRole();
      final profile = await backend.loadProfile();
      if (mounted && request == _authRequest && !_authBusy) _activate(profile);
    } catch (error) {
      if (mounted && request == _authRequest) {
        _activate(null);
        _reportError(error);
      }
    }
  }

  void _activate(UserProfile? user) {
    _profileSubscription?.cancel();
    listingStore.bindUser(user);
    if (!mounted) return;
    setState(() {
      activeUser = user;
      selectedListingId = null;
      login = true;
      if (user != null) role = user.role;
      page = user == null
          ? AppPage.auth
          : user.role == UserRole.landlord
          ? AppPage.landlordDashboard
          : AppPage.boarderHome;
    });
    if (user != null) {
      _profileSubscription = backend.db
          .collection('users')
          .doc(user.id)
          .snapshots()
          .listen((snapshot) {
            if (!mounted || activeUser?.id != user.id || !snapshot.exists) {
              return;
            }
            try {
              final profile = FirebaseBackend.profileFromData(
                user.id,
                snapshot.data()!,
              );
              setState(() => activeUser = profile);
            } catch (error) {
              _reportError(error);
            }
          }, onError: _reportError);
    }
  }

  Future<void> _saveProfile(UserProfile updated) async {
    final saved = await backend.saveProfile(updated);
    if (!mounted || activeUser?.id != updated.id) {
      throw StateError('The active account changed while saving.');
    }
    setState(() {
      activeUser = saved.profile;
      _emailVerificationSent = saved.emailVerificationSent;
      page = AppPage.profile;
    });
  }

  @override
  late final ListingStore listingStore = ListingStore(
    backend: backend,
    onError: _reportError,
  );

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    listingStore.dispose();
    super.dispose();
  }

  void openListing(Listing listing) {
    listingStore.recordView(listing.id);
    setState(() {
      selectedListingId = listing.id;
      listingOrigin = page;
      page = AppPage.listing;
    });
  }

  void _openEditListing(Listing listing) {
    final current = listingStore.byId(listing.id);
    if (activeUser?.role != UserRole.landlord ||
        current == null ||
        current.ownerId != activeUser?.id) {
      return;
    }
    setState(() {
      editListingOrigin = page == AppPage.listing
          ? AppPage.listing
          : AppPage.landlordDashboard;
      selectedListingId = listing.id;
      page = AppPage.editListing;
    });
  }

  @override
  void go(AppPage next) => setState(() => page = next);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayNear',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messenger,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        fontFamily: 'StayNearSans',
      ),
      home: Builder(
        builder: (context) {
          late Widget body;
          switch (page) {
            case AppPage.auth:
              body = AuthPage(
                login: login,
                role: role,
                onRoleChanged: (r) => setState(() => role = r),
                onLoginChanged: (v) => setState(() => login = v),
                initialError: widget.initializationError == null
                    ? null
                    : backendMessage(widget.initializationError!),
                onResetPassword: (email) {
                  _requireFirebaseConfiguration();
                  return backend.resetPassword(email);
                },
                onRegister: (draft) async {
                  _requireFirebaseConfiguration();
                  if (_authBusy) return;
                  _authBusy = true;
                  ++_authRequest;
                  late final UserProfile profile;
                  try {
                    profile = await backend.register(draft);
                  } finally {
                    _authBusy = false;
                  }
                  if (!mounted) return;
                  setState(() {
                    activeUser = null;
                    role = profile.role;
                    login = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account created successfully! '
                            'Please log in to continue.',
                          ),
                        ),
                      );
                  });
                },
                onLogin: (email, password, selectedRole) async {
                  _requireFirebaseConfiguration();
                  if (_authBusy) return false;
                  _authBusy = true;
                  ++_authRequest;
                  try {
                    final user = await backend.login(
                      email,
                      password,
                      expectedRole: selectedRole,
                    );
                    if (!mounted) return false;
                    _activate(user);
                    return true;
                  } finally {
                    _authBusy = false;
                  }
                },
              );
            case AppPage.landlordDashboard:
              body = LandlordDashboard(
                store: listingStore,
                ownerId: activeUser?.id,
                onListing: openListing,
                onEdit: _openEditListing,
                onDelete: (listing) => _confirmDelete(context, listing),
                onAddRoom: _openAddRoom,
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.editListing:
              final listing = listingStore.byId(selectedListingId);
              body = listing == null || listing.ownerId != activeUser?.id
                  ? Column(
                      children: [
                        TopBar(
                          title: 'Edit Listing',
                          onBack: () => go(AppPage.landlordDashboard),
                        ),
                        const Expanded(
                          child: EmptyState(
                            icon: Icons.home_outlined,
                            title: 'Listing no longer available',
                            text:
                                'Return to your dashboard to choose a listing.',
                          ),
                        ),
                      ],
                    )
                  : EditListingPage(
                      key: ValueKey(listing.id),
                      listing: listing,
                      onBack: () => go(editListingOrigin),
                      onProfile: () => go(AppPage.profile),
                      onSave: (updated) async {
                        if (activeUser?.role != UserRole.landlord) {
                          throw StateError(
                            'Please sign in as the listing owner.',
                          );
                        }
                        await listingStore.saveOwnedListing(
                          updated.copyWith(
                            houseInformation: {
                              ...updated.houseInformation,
                              'Landowner': activeUser!.fullName,
                            },
                          ),
                          activeUser!.id,
                        );
                        if (mounted) go(editListingOrigin);
                      },
                    );
            case AppPage.roomWizard:
              body = _buildAddRoom(context);
            case AppPage.boarderHome:
              body = BoarderDashboard(
                store: listingStore,
                onListing: openListing,
                onFavorites: () => go(AppPage.favorites),
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.favorites:
              body = FavoritesPage(
                store: listingStore,
                onListing: openListing,
                onHome: () => go(AppPage.boarderHome),
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.listing:
              body = ListenableBuilder(
                listenable: listingStore,
                builder: (context, child) {
                  final selectedListing = listingStore.byId(selectedListingId);
                  return selectedListing == null
                      ? Column(
                          children: [
                            TopBar(
                              title: 'Property Details',
                              onBack: () => go(listingOrigin),
                            ),
                            const Expanded(
                              child: EmptyState(
                                icon: Icons.home_outlined,
                                title: 'Property no longer available',
                                text: 'Return to Search to find another property.',
                              ),
                            ),
                          ],
                        )
                      : ListingPage(
                          key: ValueKey(selectedListing.id),
                          listing: selectedListing,
                          store: listingStore,
                          user: activeUser,
                          additionalInformation:
                              activeUser?.role == UserRole.landlord
                              ? {'Views': '${selectedListing.views}'}
                              : const {},
                          favorite: listingStore.isFavorite(selectedListing.id),
                          onFavorite: activeUser?.role == UserRole.landlord
                              ? null
                              : () => listingStore.toggleFavorite(
                                  selectedListing.id,
                                ),
                          onEdit:
                              activeUser?.role == UserRole.landlord &&
                                  selectedListing.ownerId == activeUser?.id
                              ? () => _openEditListing(selectedListing)
                              : null,
                          onBack: () => go(listingOrigin),
                        );
                },
              );
            case AppPage.profile:
              body = ProfilePage(
                user: activeUser,
                onEdit: () => go(AppPage.editProfile),
                onLogout: () => _logout(context),
                onHome: () => go(
                  role == UserRole.landlord
                      ? AppPage.landlordDashboard
                      : AppPage.boarderHome,
                ),
                onFavorites: () => go(AppPage.favorites),
              );
            case AppPage.editProfile:
              body = role == UserRole.boarder && activeUser != null
                  ? EditProfilePage(
                      user: activeUser!,
                      onBack: () => go(AppPage.profile),
                      onSave: (updated) async {
                        await _saveProfile(updated);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _emailVerificationSent
                                  ? 'Profile saved. Check your new email to verify the email change; keep using your current email until verified.'
                                  : 'Profile updated successfully.',
                            ),
                          ),
                        );
                      },
                    )
                  : LandownerEditProfilePage(
                      user: activeUser!,
                      onBack: () => go(AppPage.profile),
                      onSave: (updated) async {
                        await _saveProfile(updated);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _emailVerificationSent
                                  ? 'Profile saved. Check your new email to verify the email change; keep using your current email until verified.'
                                  : 'Profile updated successfully.',
                            ),
                          ),
                        );
                      },
                    );
          }
          return ScreenFrame(child: body);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Listing listing) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete Listing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete this listing?\n'
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 26,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F2F4),
                          foregroundColor: ink,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 26,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          if (listingStore.byId(listing.id)?.ownerId !=
                              activeUser?.id) {
                            return;
                          }
                          try {
                            await listingStore.deleteOwned(listing.id);
                          } catch (error) {
                            _reportError(error);
                            return;
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing deleted')),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495064),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFF44348)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (_authBusy) return;
                    _authBusy = true;
                    ++_authRequest;
                    try {
                      await backend.auth.signOut();
                      if (mounted) _activate(null);
                    } catch (error) {
                      _reportError(error);
                    } finally {
                      _authBusy = false;
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Yes', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
