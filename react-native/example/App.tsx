import React, { useState, useCallback } from 'react';
import {
  SafeAreaView,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ActivityIndicator,
  StatusBar,
} from 'react-native';
import {
  MultandoProvider,
  MultandoClient,
  ReportForm,
  useAuth,
  Locale,
} from '@multando/react-native-sdk';
import type { MultandoConfig, ReportDetail, LocationData } from '@multando/react-native-sdk';

const SDK_CONFIG: MultandoConfig = {
  baseUrl: 'https://api.multando.io',
  apiKey: 'example-api-key',
  locale: Locale.En,
};

const DEFAULT_LOCATION: LocationData = {
  latitude: 40.4168,
  longitude: -3.7038,
  address: 'Puerta del Sol, Madrid',
  city: 'Madrid',
  country: 'Spain',
};

export default function App(): React.ReactElement {
  return (
    <MultandoProvider
      config={SDK_CONFIG}
      onInitialized={() => console.log('Multando SDK initialized')}
      onError={(err) => console.error('SDK init error:', err)}
    >
      <StatusBar barStyle="dark-content" />
      <AppContent />
    </MultandoProvider>
  );
}

function AppContent(): React.ReactElement {
  const { isAuthenticated, login, isLoading: authLoading } = useAuth();

  if (authLoading) {
    return (
      <SafeAreaView style={styles.centered}>
        <ActivityIndicator size="large" color="#3B5EEF" />
        <Text style={styles.loadingText}>Initializing...</Text>
      </SafeAreaView>
    );
  }

  if (!isAuthenticated) {
    return <LoginScreen onLogin={login} />;
  }

  return <ReportScreen />;
}

interface LoginScreenProps {
  onLogin: (email: string, password: string) => Promise<void>;
}

function LoginScreen({ onLogin }: LoginScreenProps): React.ReactElement {
  const [email, setEmail] = useState('demo@multando.io');
  const [password, setPassword] = useState('password123');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      await onLogin(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }, [email, password, onLogin]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.loginContainer}>
        <Text style={styles.logoText}>Multando</Text>
        <Text style={styles.subtitle}>Report traffic infractions</Text>

        <TextInput
          style={styles.input}
          value={email}
          onChangeText={setEmail}
          placeholder="Email"
          keyboardType="email-address"
          autoCapitalize="none"
        />

        <TextInput
          style={styles.input}
          value={password}
          onChangeText={setPassword}
          placeholder="Password"
          secureTextEntry
        />

        {error && <Text style={styles.errorText}>{error}</Text>}

        <TouchableOpacity
          style={[styles.loginButton, loading && styles.loginButtonDisabled]}
          onPress={handleLogin}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#FFFFFF" />
          ) : (
            <Text style={styles.loginButtonText}>Sign In</Text>
          )}
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

function ReportScreen(): React.ReactElement {
  const handleSuccess = useCallback((result: ReportDetail | string) => {
    if (typeof result === 'string') {
      Alert.alert('Queued', `Report queued offline with ID: ${result}`);
    } else {
      Alert.alert('Success', `Report created: ${result.id}`);
    }
  }, []);

  const handleError = useCallback((err: Error) => {
    Alert.alert('Error', err.message);
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Create Report</Text>
      </View>
      <ReportForm
        location={DEFAULT_LOCATION}
        onSuccess={handleSuccess}
        onError={handleError}
        onCancel={() => Alert.alert('Cancelled')}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#666',
  },
  loginContainer: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  logoText: {
    fontSize: 32,
    fontWeight: '700',
    color: '#3B5EEF',
    textAlign: 'center',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    marginBottom: 32,
  },
  input: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
    marginBottom: 12,
    backgroundColor: '#F9FAFB',
  },
  errorText: {
    color: '#EF4444',
    fontSize: 13,
    marginBottom: 8,
    textAlign: 'center',
  },
  loginButton: {
    backgroundColor: '#3B5EEF',
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  loginButtonDisabled: {
    opacity: 0.6,
  },
  loginButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
    backgroundColor: '#3B5EEF',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});
